
local Typyka = {
    model = "Typyka HDD-1000",
    version = "1.4",

    capacity = 1024,          -- В мегабайтах (1 ГБ)
    usedSpace = 0,            -- Используемое пространство в byte
    rotationSpeed = 7200,     -- RPM
    cacheSize = 64,           -- Размер кэша в MB

    maxReadSpeed = 160,       -- MB/s
    maxWriteSpeed = 120,      -- MB/s
    currentReadSpeed = 0,
    currentWriteSpeed = 0,

    temperature = 30,         -- °C
    minTemperature = 25,      -- Минимальная температура
    idlePower = 5,            -- Вт в режиме ожидания
    activePower = 10,         -- Вт при активной работе
    maxPower = 15,            -- Максимальная мощность

    isSpinning = false,
    lastAccessTime = 0,
    accessQueue = {},
    
    totalRead = 0,            -- Всего прочитано (MB)
    totalWritten = 0,         -- Всего записано (MB)
    errors = 0,
    wearLevel = 0,            -- Уровень износа (0-100%)
    
    spinUpTime = 2,           -- Время раскрутки в секундах
    spinDownTime = 5,         -- Время остановки
    spinTimer = 0,
    
    -- Хранилище данных (1 ГБ = 1024 MB)
    storage = {},             -- Хеш-таблица для хранения данных
    sectors = 1024 * 1024,    -- Общее количество секторов (1 сектор = 1 KB)
    sectorSize = 1024,        -- 1 KB
    
    eventListeners = {
        spinUp = {},
        spinDown = {},
        read = {},
        write = {},
        error = {},
        temperatureChange = {}
    },

    motherboard = nil
}

function Typyka:addEventListener(eventType, callback)
    if self.eventListeners[eventType] then
        table.insert(self.eventListeners[eventType], callback)
    else
        print(string.format("[%s] Warning: Unknown event type '%s'", self.model, eventType))
    end
end

function Typyka:triggerEvent(eventType, ...)
    if self.eventListeners[eventType] then
        for _, callback in ipairs(self.eventListeners[eventType]) do
            callback(self, ...)
        end
    end
end

function Typyka:init(motherboard)
    self.motherboard = motherboard
    print(string.format("[%s] Initialized, connected to %s", self.model, motherboard.model))

    self.storage = {}
    self.usedSpace = 0
    self.effectiveCapacity = self.capacity

    self:addEventListener("spinUp", function(hdd)
        print(string.format("[%s] Disk spun up", hdd.model))
    end)

    self:addEventListener("spinDown", function(hdd)
        print(string.format("[%s] Disk spun down", hdd.model))
    end)

    self:addEventListener("error", function(hdd, errorType)
        print(string.format("[%s] Error: %s", hdd.model, errorType))
    end)

    return self
end

function Typyka:manageSpinning(dt)
    if #self.accessQueue > 0 then
        if not self.isSpinning then
            self.spinTimer = self.spinTimer + dt
            if self.spinTimer >= self.spinUpTime then
                self.isSpinning = true
                self.spinTimer = 0
                self:triggerEvent("spinUp")
            end
        end
    else
        if self.isSpinning then
            self.spinTimer = self.spinTimer + dt
            if self.spinTimer >= self.spinDownTime then
                self.isSpinning = false
                self.spinTimer = 0
                self:triggerEvent("spinDown")
            end
        end
    end
end

function Typyka:calculateWear(dt)
    local tempFactor = math.max(0, (self.temperature - 40) / 50)
    local activityFactor = (self.currentReadSpeed + self.currentWriteSpeed) / (self.maxReadSpeed + self.maxWriteSpeed)

    local wearIncrease = (tempFactor * 0.1 + activityFactor * 0.05) * 0.00001 * dt

    self.wearLevel = math.min(100, self.wearLevel + wearIncrease)

    if self.wearLevel > 10 then
        local capacityReduction = (self.wearLevel - 10) / 90 
        self.effectiveCapacity = self.capacity * (1 - capacityReduction * 0.1)
    else
        self.effectiveCapacity = self.capacity
    end
end

function Typyka:manageTemperature(dt)
    local oldTemp = self.temperature
    local coolingRate = 0.5

    if self.isSpinning then
        coolingRate = coolingRate - 0.2

        if self.currentReadSpeed > 0 or self.currentWriteSpeed > 0 then
            local activityHeat = (self.currentReadSpeed + self.currentWriteSpeed) / 100
            self.temperature = self.temperature + activityHeat * dt
        end
    end

    self.temperature = math.max(
        self.minTemperature,
        self.temperature - coolingRate * dt
    )

    if math.floor(oldTemp) ~= math.floor(self.temperature) then
        self:triggerEvent("temperatureChange", oldTemp, self.temperature)
    end

    if self.temperature > 50 then
        local throttle = math.min(1, (self.temperature - 50) / 20)
        self.currentReadSpeed = self.maxReadSpeed * (1 - throttle * 0.5)
        self.currentWriteSpeed = self.maxWriteSpeed * (1 - throttle * 0.7)
    else
        self.currentReadSpeed = self.maxReadSpeed
        self.currentWriteSpeed = self.maxWriteSpeed
    end
end

function Typyka:read(address, callback)
    if not self.isSpinning then
        table.insert(self.accessQueue, {
            type = "read",
            address = address,
            callback = callback,
            time = love.timer.getTime()
        })
        return nil
    end

    local bytesRead = 0
    local data = self.storage[address] or ""

    bytesRead = #data * 8

    if bytesRead > 0 then
        self.totalRead = self.totalRead + (bytesRead / (1024 * 1024))
        self:triggerEvent("read", address, bytesRead)
    end

    if callback then
        callback(data, bytesRead)
    end
    return data, bytesRead
end

function Typyka:write(address, data, callback)
    if not self.isSpinning then
        table.insert(self.accessQueue, {
            type = "write",
            address = address,
            data = data,
            callback = callback,
            time = love.timer.getTime()
        })
        return false
    end

    local oldDataSize = self.storage[address] and (#self.storage[address] * 8) or 0
    local newDataSize = #data * 8
    local sizeDifference = newDataSize - oldDataSize

    if (self.usedSpace + sizeDifference)/1024/1024 > self.effectiveCapacity then
        self.errors = self.errors + 1
        self:triggerEvent("error", "Not enough space")
        if callback then callback(false, "Not enough space") end
        return false
    end

    self.storage[address] = data
    self.usedSpace = self.usedSpace + sizeDifference

    if newDataSize > 0 then
        self.totalWritten = self.totalWritten + (newDataSize / (1024 * 1024))
    end
    
    self:triggerEvent("write", address, newDataSize)

    if callback then callback(true) end
    return true
end

function Typyka:getAllStorage()
    local json = require("json")
    return json.decode(json.encode(self.storage))
end

function Typyka:getInfo()
    return {
        model = self.model,
        capacity = self.capacity,
        effectiveCapacity = self.effectiveCapacity,
        usedSpace = self.usedSpace,
        freeSpace = self.effectiveCapacity - self.usedSpace,
        utilization = (self.usedSpace / self.effectiveCapacity) * 100,
        temperature = self.temperature,
        isSpinning = self.isSpinning,
        readSpeed = self.currentReadSpeed,
        writeSpeed = self.currentWriteSpeed,
        powerUsage = self:getPowerConsumption(),
        rotationSpeed = self.rotationSpeed,
        errors = self.errors,
        wearLevel = self.wearLevel,
        totalRead = self.totalRead,
        totalWritten = self.totalWritten,
        sectorSize = self.sectorSize,
        sectorsUsed = self:calculateUsedSectors()
    }
end

function Typyka:calculateUsedSectors()
    local count = 0
    for _ in pairs(self.storage) do
        count = count + 1
    end
    return count
end

function Typyka:getPowerConsumption()
    if not self.isSpinning then
        return self.idlePower
    end
    
    local basePower = self.activePower
    local activityPower = (self.currentReadSpeed + self.currentWriteSpeed) / 
                         (self.maxReadSpeed + self.maxWriteSpeed) * (self.maxPower - self.activePower)
    
    return basePower + activityPower
end

function Typyka:update(dt)
    self:manageSpinning(dt)
    self:manageTemperature(dt)
    self:calculateWear(dt)

    if self.isSpinning and #self.accessQueue > 0 then
        local request = table.remove(self.accessQueue, 1)
        
        if request.type == "read" then
            local data = self:read(request.address, request.callback)
            return data
        elseif request.type == "write" then
            local success = self:write(request.address, request.data, request.callback)
            return success
        end
    end
end

function Typyka:saveToFile(filename)
    filename = filename or "Typyka_data.temp"

    local saveData = {
        meta = {
            model = self.model,
            version = self.version,
            capacity = self.capacity,
            usedSpace = self.usedSpace,
            sectors = self.sectors,
            sectorSize = self.sectorSize,
            totalRead = self.totalRead,
            totalWritten = self.totalWritten,
            errors = self.errors,
            wearLevel = self.wearLevel
        },
        storage = {}
    }

    for sector, data in pairs(self.storage) do
        if type(data) == "string" then
            saveData.storage[tostring(sector)] = love.data.encode("string", "base64", data)
        end
    end

    local json = require("json")
    local success, jsonStr = pcall(json.encode, saveData)
    if not success then
        self:triggerEvent("error", "Failed to encode save data: " .. jsonStr)
        return false
    end

    local success, message = pcall(function()
        local file = love.filesystem.newFile(filename)
        file:open("w")
        file:write(jsonStr)
        file:close()
    end)

    if not success then
        self:triggerEvent("error", "Failed to save file: " .. message)
        return false
    end

    return true
end

function Typyka:loadFromFile(filename)
    filename = filename or "Typyka_data.temp"

    if not love.filesystem.getInfo(filename) then
        self:triggerEvent("error", "Save file not found")
        return false
    end

    local success, jsonStr = pcall(function()
        local file = love.filesystem.newFile(filename)
        file:open("r")
        local content = file:read()
        file:close()
        return content
    end)

    if not success then
        self:triggerEvent("error", "Failed to read file: " .. jsonStr)
        return false
    end

    local json = require("json")
    local success, saveData = pcall(json.decode, jsonStr)
    if not success then
        self:triggerEvent("error", "Failed to decode save data: " .. saveData)
        return false
    end

    self.storage = {}
    self.usedSpace = 0

    if saveData.meta then
        self.model = saveData.meta.model or self.model
        self.version = saveData.meta.version or self.version
        self.capacity = saveData.meta.capacity or self.capacity
        self.sectors = saveData.meta.sectors or self.sectors
        self.sectorSize = saveData.meta.sectorSize or self.sectorSize
        self.totalRead = saveData.meta.totalRead or self.totalRead
        self.totalWritten = saveData.meta.totalWritten or self.totalWritten
        self.errors = saveData.meta.errors or self.errors
        self.wearLevel = saveData.meta.wearLevel or self.wearLevel
    end

    if saveData.storage then
        for sector, encodedData in pairs(saveData.storage) do
            if sector then
                local data = love.data.decode("string", "base64", encodedData)
                self.storage[sector] = data
                self.usedSpace = self.usedSpace + #data * 8
            end
        end
    end

    return true
end

return Typyka
-- RAM/Unsa_2x1gb.lua
local json = require("json")

local Unsa2x1GB = {
    model = "Unsa DDR1 2x100mb",
    version = "1.0",
    manufacturer = "Unsa Tech",

    capacity = 200 * 1024 * 1024,  -- Общий объем в байтах (200MB)
    frequency = 1000,               -- Частота в MHz
    latency = 9,                    -- CAS Latency
    voltage = 1.5,                  -- Рабочее напряжение
    channels = 2,                   -- Количество каналов

    timings = {
        tCL = 9,
        tRCD = 9,
        tRP = 9,
        tRAS = 24,
        tRC = 33
    },

    powerUsage = {
        idle = 2,             -- Потребление в режиме ожидания (Вт)
        active = 5,           -- Потребление при активной работе (Вт)
        max = 7               -- Максимальное потребление (Вт)
    },

    currentPower = 0,
    temperature = 35,         -- Температура модуля
    utilization = 0,          -- Загрузка памяти (0-1)
    errors = 0,               -- Счетчик ошибок
    usedMemory = 0,           -- Использованная память в байтах

    motherboard = nil,

    _memory = {},
    _addressMap = {},         -- Для отслеживания размера объектов по адресу
    _lastAccessTime = 0
}

function Unsa2x1GB:init(motherboard)
    self.motherboard = motherboard
    
    print(string.format("[%s] Initialized, connected to %s", 
        self.model, motherboard.model))

    if motherboard.memoryController then
        motherboard.memoryController:registerMemory(self)
    end
    
    return self
end

function Unsa2x1GB:_getDataSize(value)
    local t = type(value)
    
    if t == "number" then
        return 8
    elseif t == "string" then
        return #value
    elseif t == "boolean" then
        return 1
    elseif t == "function" then
        return #string.dump(value)
    elseif t == "table" then
        local success, encoded = pcall(json.encode, value)
        return success and #encoded or 0
    elseif t == "nil" then
        return 0
    else
        return 1
    end
end

function Unsa2x1GB:read(address, size)
    size = size or 1
    local data = {}

    local delay = self:_calculateLatency()
    self:_simulateBusy(delay)
    
    for i = address, address + size - 1 do
        table.insert(data, self._memory[i] or 0)
    end
    
    self.utilization = math.min(1, self.usedMemory / self.capacity)
    self.currentPower = self.powerUsage.active
    self._lastAccessTime = os.clock()
    
    return unpack(data)
end

function Unsa2x1GB:write(address, ...)
    local values = {...}
    local totalSize = 0

    for i = 1, #values do
        local size = self:_getDataSize(values[i])
        totalSize = totalSize + size

        if self._memory[address + i - 1] then
            local oldSize = self:_getDataSize(self._memory[address + i - 1])
            self.usedMemory = self.usedMemory - oldSize
        end
    end

    if self.usedMemory + totalSize > self.capacity then
        self.errors = self.errors + 1
        error(string.format("[%s] ERROR: Not enough memory! Requested: %d bytes, Available: %d bytes",
            self.model, totalSize, self.capacity - self.usedMemory))
        return false
    end
    
    local delay = self:_calculateLatency()
    self:_simulateBusy(delay)

    for i = 1, #values do
        self._memory[address + i - 1] = values[i]
        self.usedMemory = self.usedMemory + self:_getDataSize(values[i])
    end
    
    self.utilization = self.usedMemory / self.capacity
    self.currentPower = self.powerUsage.active
    self._lastAccessTime = os.clock()
    return true
end

function Unsa2x1GB:free(address, count)
    count = count or 1
    local freed = 0
    
    for i = address, address + count - 1 do
        if self._memory[i] then
            freed = freed + self:_getDataSize(self._memory[i])
            self._memory[i] = nil
        end
    end
    
    self.usedMemory = self.usedMemory - freed
    self.utilization = self.usedMemory / self.capacity
    
    return freed
end

function Unsa2x1GB:_calculateLatency()
    local baseLatency = (self.timings.tCL / self.frequency) * 1e-6
    
    local loadPenalty = self.utilization * 0.2 * baseLatency

    local jitter = math.random() * 0.1 * baseLatency
    
    return baseLatency + loadPenalty + jitter
end

function Unsa2x1GB:_simulateBusy(duration)
    love.timer.sleep(duration)
    self.temperature = math.min(85, self.temperature + duration * 10)
end

function Unsa2x1GB:update(dt)
    self.temperature = math.max(30, self.temperature - dt * 5)

    if os.clock() - self._lastAccessTime > 0.1 then
        self.currentPower = self.powerUsage.idle
        self.utilization = math.max(0, self.utilization - dt * 0.1)
    end

    if self.temperature > 80 and math.random() < 0.01 then
        self.errors = self.errors + 1
        print(string.format("[%s] WARNING: High temperature (%d°C)! Errors: %d", 
            self.model, self.temperature, self.errors))
    end
end

function Unsa2x1GB:getPowerConsumption()
    return self.currentPower
end

function Unsa2x1GB:getInfo()
    return {
        model = self.model,
        capacity = self.capacity,
        freeMemory = self.capacity - self.usedMemory,
        frequency = self.frequency,
        utilization = self.utilization * 100,
        temperature = self.temperature,
        powerUsage = self.currentPower,
        voltage = self.voltage,
        errors = self.errors,
        timings = string.format("%d-%d-%d-%d", 
            self.timings.tCL, self.timings.tRCD, 
            self.timings.tRP, self.timings.tRAS)
    }
end

return Unsa2x1GB
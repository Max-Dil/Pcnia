local bit = require("bit")
local arch = require("CPU.arch.8")
local Processor = {
    model = "Zero1",
    version = "1.4",

    threads = {},   -- Потоки (корутины)
    currentThread = 1,
    threadLoad = {}, -- Загрузка каждого потока

    baseClockSpeed = 10,  -- базовая частота (операций в секунду)
    currentClockSpeed = 10,
    clockAccumulator = 0,

    autoBoost = true,
    maxClockSpeed = 20,   -- максимальная частота при разгоне
    minClockSpeed = 1,    -- минимальная частота при троттлинге
    boostThreshold = 0.7,   -- порог нагрузки для разгона
    throttleThreshold = 0.9, -- порог для троттлинга

    powerUsage = 0,         -- текущее энергопотребление
    maxPowerUsage = 5,    -- максимальное энергопотребление
    TPD = 0,               -- тепловыделение (Thermal Design Power)
    maxTPD = 2,           -- максимальное тепловыделение
    coolingRate = 0.5,     -- скорость охлаждения
    heatingRate = 0.8,     -- скорость нагрева
    thermalThrottle = false, -- флаг троттлинга

    lastTime = 0,
    cpuLoad = 0,          -- Загрузка CPU в %
    performanceFactor = 1, -- Фактор производительности (0-1)

    input_current = 10,
}

function Processor:applyLoadDelay()
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.1
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end
end

function Processor:init()
    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
    self.cpuLoad = 0
    self.performanceFactor = 1
end

function Processor:setGPU(gpu)
    self.gpu = gpu
end

function Processor:updatePerformanceFactor()
    local loadFactor = 1 - math.min(1, #self.threads / 8)
    local thermalFactor = 1 - math.min(1, self.TPD / self.maxTPD)
    
    self.performanceFactor = math.min(loadFactor, thermalFactor)

    if self.cpuLoad > 80 then
        self.performanceFactor = self.performanceFactor * 0.8
    end
    
    self.performanceFactor = math.max(0.1, self.performanceFactor)
end

function Processor:updateCpuLoad()
    local activeThreads = 0
    for i, thread in ipairs(self.threads) do
        if coroutine.status(thread) ~= "dead" then
            activeThreads = activeThreads + 1
        end
    end
    
    local maxThreads = 16
    local clockFactor = self.currentClockSpeed / self.baseClockSpeed
    self.cpuLoad = math.min(100, (activeThreads / maxThreads) * 100 * clockFactor)
end

function Processor:addThread(func)
    if self:calculatePotentialPower(#self.threads) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false
    end

    local co = coroutine.create(function()
        local env = arch(self)

        setmetatable(env, {__index = _G})
        setfenv(func, env)

        func()
    end)

    table.insert(self.threads, co)
    self:updatePowerUsage()
    return true, co
end

function Processor:calculatePotentialPower(numThreads)
    local load = numThreads / 8
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function Processor:setMotherboard(motherboard)
    self.motherboard = motherboard
end

function Processor:removeThread(index)
    table.remove(self.threads, index)
    self:updatePowerUsage()
end

function Processor:searchThread(co)
    for i = 1, #self.threads do
        if self.threads[i] == co then
            return i
        end
    end
end

function Processor:updatePowerUsage()
    local load = #self.threads / 8
    local newPower = self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)

    if newPower > self.maxPowerUsage then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed * (self.maxPowerUsage / newPower)
        )
        newPower = self.maxPowerUsage
    end
    
    self.powerUsage = newPower
    self:updateTPD()
end

function Processor:updateTPD()
    local targetTPD = self.powerUsage * 0.9

    if targetTPD > self.TPD then
        self.TPD = math.min(targetTPD, self.TPD + self.heatingRate)
    else
        self.TPD = math.max(0, self.TPD - self.coolingRate)
    end

    if self.TPD > self.maxTPD * self.throttleThreshold then
        self.thermalThrottle = true
    elseif self.TPD < self.maxTPD * 0.7 then
        self.thermalThrottle = false
    end
end

function Processor:autoBoostClock()
    if not self.autoBoost then return end

    if self.thermalThrottle then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed - 20
        )
        return
    end

    local load = #self.threads / 8
    if load > self.boostThreshold and self.TPD < self.maxTPD * 0.8 then
        self.currentClockSpeed = math.min(
            self.maxClockSpeed,
            self.currentClockSpeed + 10
        )
    else
        self.currentClockSpeed = math.max(
            self.baseClockSpeed,
            self.currentClockSpeed - 5
        )
    end
end

function Processor:tick()
    if #self.threads == 0 then return end

    self:updatePerformanceFactor()
    self:updateCpuLoad()

    if self.performanceFactor < 0.5 then
        local delay = (0.5 - self.performanceFactor) * 0.05
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end

    local thread = self.threads[self.currentThread]
    if not thread then
        self.currentThread = self.currentThread % #self.threads + 1
        return
    end

    if coroutine.status(thread) == "dead" then
        table.remove(self.threads, self.currentThread)
        self.threadLoad[thread] = nil
        self:updatePowerUsage()
        self:updateCpuLoad()
        return
    end

    self.threadLoad[thread] = (self.threadLoad[thread] or 0) + 1
    
    local ok, err = coroutine.resume(thread)
    if not ok then
        print("Thread error:", err)
        table.remove(self.threads, self.currentThread)
        self.threadLoad[thread] = nil
        self:updatePowerUsage()
        self:updateCpuLoad()
        return
    end

    self.currentThread = self.currentThread % #self.threads + 1
end

function Processor:update(dt)
    if self.input_current < math.min(self.powerUsage, self.maxPowerUsage) then self.input_current = 0 return end
    self.lastTime = love.timer.getTime()

    self:autoBoostClock()
    self:updatePowerUsage()
    self:updateTPD()

    self.clockAccumulator = self.clockAccumulator + dt

    local ticks = math.floor(self.clockAccumulator * self.currentClockSpeed)
    if ticks > 0 then
        for i = 1, ticks do
            self:tick()
        end
        self.clockAccumulator = self.clockAccumulator - ticks / self.currentClockSpeed

        if Processor.updateComponents then
            Processor.updateComponents(dt)
        end
    end
end

function Processor:getInfo()
    return {
        clockSpeed = self.currentClockSpeed,
        baseClockSpeed = self.baseClockSpeed,
        maxClockSpeed = self.maxClockSpeed,
        minClockSpeed = self.minClockSpeed,
        powerUsage = self.powerUsage,
        maxPowerUsage = self.maxPowerUsage,
        TPD = self.TPD,
        maxTPD = self.maxTPD,
        threads = #self.threads,
        activeThreads = self:countActiveThreads(),
        autoBoost = self.autoBoost,
        thermalThrottle = self.thermalThrottle,
        cpuLoad = self.cpuLoad,
        performanceFactor = self.performanceFactor,
        threadLoads = self:getThreadLoads()
    }
end

function Processor:countActiveThreads()
    local count = 0
    for _, thread in ipairs(self.threads) do
        if coroutine.status(thread) ~= "dead" then
            count = count + 1
        end
    end
    return count
end

function Processor:getThreadLoads()
    local loads = {}
    for thread, load in pairs(self.threadLoad) do
        if coroutine.status(thread) ~= "dead" then
            loads[#loads+1] = {
                thread = tostring(thread),
                load = load
            }
        end
    end
    return loads
end

return Processor
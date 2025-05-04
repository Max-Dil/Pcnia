--[[
Ore - ограненные камни, спасение новых пользователей
]]

local arch = require("CPU.arch.16")
local bit = require("bit")
local Processor = {
    model = "Ore",
    version = "1.1",

    registers = {
        AX = 0,  -- 16-битный аккумулятор
        BX = 0,  -- Базовый регистр
        CX = 0,  -- Счетчик
        DX = 0,  -- Данные
        SI = 0,  -- Source Index
        DI = 0,  -- Destination Index
        BP = 0,  -- Base Pointer
        SP = 0xFFFF,  -- Stack Pointer (инициализирован в верхушку стека)
        IP = 0,  -- Instruction Pointer
        FLAGS = 0, 
    },

    FLAGS_MASK = {
        CARRY      = 0x0001,
        ZERO       = 0x0002,
        SIGN       = 0x0004,
        OVERFLOW   = 0x0008,
        INTERRUPT  = 0x0020,
        DIRECTION  = 0x0400,
    },

    threads = {},
    currentThread = 1,
    threadLoad = {},

    baseClockSpeed = 80,
    currentClockSpeed = 80,
    clockAccumulator = 0,

    autoBoost = true,
    maxClockSpeed = 100,
    minClockSpeed = 5,
    boostThreshold = 0.7,
    throttleThreshold = 0.9,

    powerUsage = 0,
    maxPowerUsage = 20,
    TPD = 2,
    maxTPD = 15,
    coolingRate = 0.6,
    heatingRate = 0.9,

    lastTime = 0,
    cpuLoad = 0,
    performanceFactor = 1,

    input_current = 20,
}

Processor.applyLoadDelay = function(self)
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.1
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end
end

Processor.init = function(self)
    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
    self.cpuLoad = 0
    self.performanceFactor = 1
    for k, v in pairs(self.registers) do
        self.registers[k] = 0
    end
    self.registers.SP = 0xFFFF
end

Processor.setFlag = function(self, flag, value)
    self:applyLoadDelay()
    if value then
        self.registers.FLAGS = bit.bor(self.registers.FLAGS, flag)
    else
        self.registers.FLAGS = bit.band(self.registers.FLAGS, bit.bnot(flag))
    end
end

Processor.getFlag = function(self, flag)
    self:applyLoadDelay()
    return bit.band(self.registers.FLAGS, flag) ~= 0
end

Processor.add16 = function(self, a, b)
    self:applyLoadDelay()
    local result = a + b
    self:setFlag(self.FLAGS_MASK.CARRY, result > 0xFFFF)
    self:setFlag(self.FLAGS_MASK.ZERO, bit.band(result, 0xFFFF) == 0)
    self:setFlag(self.FLAGS_MASK.SIGN, bit.band(result, 0x8000) ~= 0)
    self:setFlag(self.FLAGS_MASK.OVERFLOW, (bit.bxor(a, b) == 0) and (bit.bxor(a, result) ~= 0))
    return bit.band(result, 0xFFFF)
end

Processor.sub16 = function(self, a, b)
    self:applyLoadDelay()
    local result = a - b
    self:setFlag(self.FLAGS_MASK.CARRY, a < b)
    self:setFlag(self.FLAGS_MASK.ZERO, bit.band(result, 0xFFFF) == 0)
    self:setFlag(self.FLAGS_MASK.SIGN, bit.band(result, 0x8000) ~= 0)
    self:setFlag(self.FLAGS_MASK.OVERFLOW, (bit.bxor(a, b) ~= 0) and (bit.bxor(a, result) ~= 0))
    return bit.band(result, 0xFFFF)
end

Processor.addThread = function(self, func)
    if self:calculatePotentialPower(#self.threads + 1) > self.maxPowerUsage then
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

function Processor:updatePerformanceFactor()
    local loadFactor = 1 - math.min(1, #self.threads / 16)
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
    
    local maxThreads = 32
    local clockFactor = self.currentClockSpeed / self.baseClockSpeed
    self.cpuLoad = math.min(100, (activeThreads / maxThreads) * 100 * clockFactor)
end


function Processor:calculatePotentialPower(numThreads)
    local load = numThreads / 16
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
    local load = #self.threads / 16
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

function Processor:setGPU(gpu)
    self.gpu = gpu
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
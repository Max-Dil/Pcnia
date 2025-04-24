local bit = require("bit")

local ProcessorCore = {
    model = "Zero2",
    version = "1.0",

    registers = {
        A = 0,      -- Accumulator
        X = 0,      -- X Register
        Y = 0,      -- Y Register
        PC = 0,     -- Program Counter
        SP = 128,   -- Stack Pointer (starts at 128)
        SR = 0,     -- Status Register (flags)
    },

    currentThread = 1,
    threads = {},   -- Threads (coroutines)
}

function ProcessorCore:init()
    self.registers.SP = 128
    self.gpu = nil
end

function ProcessorCore:LDA(value)
    self.registers.A = value
end

function ProcessorCore:STA(addr)
    self.motherboard:writeMemory(addr, self.registers.A)
end

function ProcessorCore:LDX(value)
    self.registers.X = value
end

function ProcessorCore:STX(addr)
    self.motherboard:writeMemory(addr, self.registers.X)
end

function ProcessorCore:LDY(value)
    self.registers.Y = value
end

function ProcessorCore:STY(addr)
    self.motherboard:writeMemory(addr, self.registers.Y)
end

function ProcessorCore:ADD(a, b)
    return (a or self.registers.A) + (b or 0)
end

function ProcessorCore:SUB(a, b)
    return (a or self.registers.A) - (b or 0)
end

function ProcessorCore:MUL(a, b)
    return (a or self.registers.A) * (b or 1)
end

function ProcessorCore:DIV(a, b)
    return (a or self.registers.A) / (b or 1)
end

function ProcessorCore:AND(a, b)
    return bit.band(a or self.registers.A, b or 0)
end

function ProcessorCore:OR(a, b)
    return bit.bor(a or self.registers.A, b or 0)
end

function ProcessorCore:XOR(a, b)
    return bit.bxor(a or self.registers.A, b or 0)
end

function ProcessorCore:NOT(a)
    return bit.bnot(a or self.registers.A)
end

function ProcessorCore:SHL(a, bits)
    return bit.lshift(a or self.registers.A, bits or 1)
end

function ProcessorCore:SHR(a, bits)
    return bit.rshift(a or self.registers.A, bits or 1)
end

function ProcessorCore:CMP(a, b)
    local result = (a or self.registers.A) - (b or 0)
    if result == 0 then
        self.registers.SR = bit.bor(self.registers.SR, 0x02)
    else
        self.registers.SR = bit.band(self.registers.SR, bit.bnot(0x02))
    end
    return result
end

function ProcessorCore:PUSH(value)
    self.motherboard:writeMemory(self.registers.SP, value or self.registers.A)
    self.registers.SP = self.registers.SP + 1
end

function ProcessorCore:POP()
    self.registers.SP = self.registers.SP - 1
    return self.motherboard:readMemory(self.registers.SP)
end

function ProcessorCore:DRW(x, y, r, g, b)
    if self.gpu then
        self.gpu:drawPixel(x, y, {r, g, b})
    end
end

function ProcessorCore:DTX(x, y, text, color, scale)
    if self.gpu then
        self.gpu:drawText(x, y, text, color, scale)
    end
end

function ProcessorCore:SLEEP(seconds)
    local start = self.lastTime or love.timer.getTime()
    while (love.timer.getTime() - start) < seconds do
        coroutine.yield()
    end
end

function ProcessorCore:addThread(func)
    local co = coroutine.create(function()
        local env = {
            LDA = function(v) coroutine.yield() return self:LDA(v) end,
            STA = function(a) coroutine.yield() return self:STA(a) end,
            LDX = function(v) coroutine.yield() return self:LDX(v) end,
            STX = function(a) coroutine.yield() return self:STX(a) end,
            LDY = function(v) coroutine.yield() return self:LDY(v) end,
            STY = function(a) coroutine.yield() return self:STY(a) end,
            ADD = function(a, b) coroutine.yield() return self:ADD(a, b) end,
            SUB = function(a, b) coroutine.yield() return self:SUB(a, b) end,
            MUL = function(a, b) coroutine.yield() return self:MUL(a, b) end,
            DIV = function(a, b) coroutine.yield() return self:DIV(a, b) end,
            AND = function(a, b) coroutine.yield() return self:AND(a, b) end,
            OR = function(a, b) coroutine.yield() return self:OR(a, b) end,
            XOR = function(a, b) coroutine.yield() return self:XOR(a, b) end,
            NOT = function(a) coroutine.yield() return self:NOT(a) end,
            SHL = function(a, b) coroutine.yield() return self:SHL(a, b) end,
            SHR = function(a, b) coroutine.yield() return self:SHR(a, b) end,
            CMP = function(a, b) coroutine.yield() return self:CMP(a, b) end,
            PUSH = function(v) coroutine.yield() return self:PUSH(v) end,
            POP = function() coroutine.yield() return self:POP() end,
            DRW = function(x, y, r, g, b) coroutine.yield() return self:DRW(x, y, r, g, b) end,
            DTX = function(x, y, text, color, scale) coroutine.yield() return self:DTX(x, y, text, color, scale) end,
            SLEEP = function(s) return self:SLEEP(s) end,

            A = function() coroutine.yield() return self.registers.A end,
            X = function() coroutine.yield() return self.registers.X end,
            Y = function() coroutine.yield() return self.registers.Y end,

            read = function(addr) coroutine.yield() return self.motherboard:readMemory(addr) end,
            write = function(addr, value) coroutine.yield() return self.motherboard:writeMemory(addr, value) end,

            print = function (...) coroutine.yield() print(...) end,
            pcall = function (...) coroutine.yield() return pcall(...) end
        }

        setmetatable(env, {__index = _G})
        setfenv(func, env)

        func()
    end)

    table.insert(self.threads, co)
    return true
end

function ProcessorCore:tick()
    if #self.threads == 0 then return end

    local thread = self.threads[self.currentThread]
    if not thread then
        self.currentThread = self.currentThread % #self.threads + 1
        return
    end

    if coroutine.status(thread) == "dead" then
        table.remove(self.threads, self.currentThread)
        return
    end

    local ok, err = coroutine.resume(thread)
    if not ok then
        print("Thread error:", err)
        table.remove(self.threads, self.currentThread)
        return
    end

    self.currentThread = self.currentThread % #self.threads + 1
end

-- Dual-core processor implementation
local DualCoreProcessor = {
    model = "Zero2DC",
    version = "1.0",
    
    cores = {},
    currentCore = 1,
    
    -- Shared properties
    baseClockSpeed = 150,
    currentClockSpeed = 150,
    clockAccumulator = 0,
    
    autoBoost = true,
    maxClockSpeed = 200,
    minClockSpeed = 1,
    boostThreshold = 0.7,
    throttleThreshold = 0.9,
    
    powerUsage = 0,
    maxPowerUsage = 15,  -- Increased for dual-core
    TPD = 0,
    maxTPD = 8,         -- Increased thermal limit
    coolingRate = 0.2,
    heatingRate = 0.6,  -- Increased heating rate for dual-core
    thermalThrottle = false,
    
    lastTime = 0,

    motherboard = nil
}

function DualCoreProcessor:init()
    -- Initialize two cores
    self.cores[1] = setmetatable({}, {__index = ProcessorCore})
    self.cores[2] = setmetatable({}, {__index = ProcessorCore})
    self.cores[1]:init()
    self.cores[2]:init()
    
    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
end

function DualCoreProcessor:setGPU(gpu)
    self.gpu = gpu
    self.cores[1].gpu = gpu
    self.cores[2].gpu = gpu
end

function DualCoreProcessor:setMotherboard(motherboard)
    self.motherboard = motherboard
    self.cores[1].motherboard = motherboard
    self.cores[2].motherboard = motherboard
end

function DualCoreProcessor:addThread(func)
    local coreToUse = (#self.cores[1].threads <= #self.cores[2].threads) and 1 or 2
    
    if self:calculatePotentialPower(#self.cores[1].threads + #self.cores[2].threads + 1) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false
    end
    
    local success = self.cores[coreToUse]:addThread(func)
    if success then
        self:updatePowerUsage()
    end
    return success
end

function DualCoreProcessor:removeThread(index)
    if index <= #self.cores[1].threads then
        table.remove(self.cores[1].threads, index)
    else
        local core2Index = index - #self.cores[1].threads
        table.remove(self.cores[2].threads, core2Index)
    end
    self:updatePowerUsage()
end

function DualCoreProcessor:calculatePotentialPower(numThreads)
    local load = numThreads / 16
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function DualCoreProcessor:updatePowerUsage()
    local totalThreads = #self.cores[1].threads + #self.cores[2].threads
    local load = totalThreads / 16
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

function DualCoreProcessor:updateTPD()
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

function DualCoreProcessor:autoBoostClock()
    if not self.autoBoost then return end

    if self.thermalThrottle then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed - 20
        )
        return
    end

    local totalThreads = #self.cores[1].threads + #self.cores[2].threads
    local load = totalThreads / 16
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

function DualCoreProcessor:tick()
    self.cores[1]:tick()
    self.cores[2]:tick()
end

function DualCoreProcessor:update(dt)
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
    end
end

function DualCoreProcessor:getInfo()
    local core1Threads = #self.cores[1].threads
    local core2Threads = #self.cores[2].threads
    
    return {
        clockSpeed = self.currentClockSpeed,
        baseClockSpeed = self.baseClockSpeed,
        maxClockSpeed = self.maxClockSpeed,
        minClockSpeed = self.minClockSpeed,
        powerUsage = self.powerUsage,
        maxPowerUsage = self.maxPowerUsage,
        TPD = self.TPD,
        maxTPD = self.maxTPD,
        threads = core1Threads + core2Threads,
        core1Threads = core1Threads,
        core2Threads = core2Threads,
        autoBoost = self.autoBoost,
        thermalThrottle = self.thermalThrottle
    }
end

return DualCoreProcessor
local bit = require("bit")
local Processor = {
    model = "Zero1",
    version = "1.2",

    registers = {
        A = 0,      -- Аккумулятор
        X = 0,      -- Регистр X
        Y = 0,      -- Регистр Y
        PC = 0,     -- Счетчик команд
        SP = 128,   -- Указатель стека (начинается с 128)
        SR = 0,     -- Регистр статуса (флаги)
    },

    threads = {},   -- Потоки (корутины)
    currentThread = 1,

    baseClockSpeed = 150,  -- базовая частота (операций в секунду)
    currentClockSpeed = 150,
    clockAccumulator = 0,

    autoBoost = true,
    maxClockSpeed = 200,   -- максимальная частота при разгоне
    minClockSpeed = 1,    -- минимальная частота при троттлинге
    boostThreshold = 0.7,   -- порог нагрузки для разгона
    throttleThreshold = 0.9, -- порог для троттлинга

    powerUsage = 0,         -- текущее энергопотребление
    maxPowerUsage = 10,    -- максимальное энергопотребление
    TPD = 0,               -- тепловыделение (Thermal Design Power)
    maxTPD = 5,           -- максимальное тепловыделение
    coolingRate = 0.5,     -- скорость охлаждения
    heatingRate = 0.8,     -- скорость нагрева
    thermalThrottle = false, -- флаг троттлинга

    lastTime = 0,
}

function Processor:init()
    self.registers.SP = 128
    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
end

function Processor:LDA(value)
    self.registers.A = value
end

function Processor:STA(addr)
    self.motherboard:writeMemory(addr, self.registers.A)
end

function Processor:LDX(value)
    self.registers.X = value
end

function Processor:STX(addr)
    self.motherboard:writeMemory(addr, self.registers.X)
end

function Processor:LDY(value)
    self.registers.Y = value
end

function Processor:STY(addr)
    self.motherboard:writeMemory(addr, self.registers.Y)
end

function Processor:ADD(a, b)
    return (a or self.registers.A) + (b or 0)
end

function Processor:SUB(a, b)
    return (a or self.registers.A) - (b or 0)
end

function Processor:MUL(a, b)
    return (a or self.registers.A) * (b or 1)
end

function Processor:DIV(a, b)
    return (a or self.registers.A) / (b or 1)
end

function Processor:AND(a, b)
    return bit.band(a or self.registers.A, b or 0)
end

function Processor:OR(a, b)
    return bit.bor(a or self.registers.A, b or 0)
end

function Processor:XOR(a, b)
    return bit.bxor(a or self.registers.A, b or 0)
end

function Processor:NOT(a)
    return bit.bnot(a or self.registers.A)
end

function Processor:SHL(a, bits)
    return bit.lshift(a or self.registers.A, bits or 1)
end

function Processor:SHR(a, bits)
    return bit.rshift(a or self.registers.A, bits or 1)
end

function Processor:CMP(a, b)
    local result = (a or self.registers.A) - (b or 0)
    if result == 0 then
        self.registers.SR = bit.bor(self.registers.SR, 0x02)
    else
        self.registers.SR = bit.band(self.registers.SR, bit.bnot(0x02))
    end
    return result
end

function Processor:PUSH(value)
    self.motherboard:writeMemory(self.registers.SP, value or self.registers.A)
    self.registers.SP = self.registers.SP + 1
end

function Processor:POP()
    self.registers.SP = self.registers.SP - 1
    return self.motherboard:readMemory(self.registers.SP)
end

function Processor:DRW(x, y, r, g, b)
    if self.gpu then
        self.gpu:drawPixel(x, y, {r, g, b})
    end
end

function Processor:DTX(x, y, text, color, scale)
    if self.gpu then
        self.gpu:drawText(x, y, text, color, scale)
    end
end

function Processor:SLEEP(seconds)
    local start = self.lastTime or love.timer.getTime()
    while (love.timer.getTime() - start) < seconds do
        coroutine.yield()
    end
end

function Processor:setGPU(gpu)
    self.gpu = gpu
end

function Processor:addThread(func)
    if self:calculatePotentialPower(#self.threads + 1) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false
    end

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

            print = function (...) coroutine.yield() print(...) end
        }

        setmetatable(env, {__index = _G})
        setfenv(func, env)

        func()
    end)

    table.insert(self.threads, co)
    self:updatePowerUsage()
    return true
end

function Processor:calculatePotentialPower(numThreads)
    local load = numThreads / 8
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function Processor:removeThread(index)
    table.remove(self.threads, index)
    self:updatePowerUsage()
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

    if self.currentClockSpeed < self.baseClockSpeed then
        local delay = (1/self.currentClockSpeed) - (1/self.baseClockSpeed)
        if delay > 0 then
            local start = love.timer.getTime()
            while (love.timer.getTime() - start) < delay do
            end
        end
    end

    local thread = self.threads[self.currentThread]
    if not thread then
        self.currentThread = self.currentThread % #self.threads + 1
        return
    end

    if coroutine.status(thread) == "dead" then
        table.remove(self.threads, self.currentThread)
        self:updatePowerUsage()
        return
    end

    local ok, err = coroutine.resume(thread)
    if not ok then
        print("Thread error:", err)
        table.remove(self.threads, self.currentThread)
        self:updatePowerUsage()
        return
    end

    self.currentThread = self.currentThread % #self.threads + 1
end

function Processor:update(dt)
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
        autoBoost = self.autoBoost,
        thermalThrottle = self.thermalThrottle
    }
end

return Processor
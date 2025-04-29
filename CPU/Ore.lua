--[[
Ore - ограненные камни, спасение новых пользователей
]]

local bit = require("bit")
local Processor = {
    model = "Ore",
    version = "1.0",

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

Processor.DRW = function(self, x, y, r, g, b)
    self:applyLoadDelay()
    if self.gpu then
        self.gpu:drawPixel(x, y, {r, g, b})
    end
end

Processor.DTX = function(self, x, y, text, color, scale)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawText(x, y, text, color, scale)
        end
    end
end

Processor.DRE = function(self, x, y, width, height, color)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawRectangle(x, y, width, height, color)
        end
    end
end

Processor.DRM = function(self, x, y, data)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawImage(x, y, data)
        end
    end
end

Processor.SLEEP = function(self, seconds)
    self:applyLoadDelay()
    local start = self.lastTime or love.timer.getTime()
    while (love.timer.getTime() - start) < seconds do
        coroutine.yield()
    end
end

Processor.setFlag = function(self, flag, value)
    if value then
        self.registers.FLAGS = bit.bor(self.registers.FLAGS, flag)
    else
        self.registers.FLAGS = bit.band(self.registers.FLAGS, bit.bnot(flag))
    end
end

Processor.getFlag = function(self, flag)
    return bit.band(self.registers.FLAGS, flag) ~= 0
end

Processor.add16 = function(self, a, b)
    local result = a + b
    self:setFlag(self.FLAGS_MASK.CARRY, result > 0xFFFF)
    self:setFlag(self.FLAGS_MASK.ZERO, bit.band(result, 0xFFFF) == 0)
    self:setFlag(self.FLAGS_MASK.SIGN, bit.band(result, 0x8000) ~= 0)
    self:setFlag(self.FLAGS_MASK.OVERFLOW, (bit.bxor(a, b) == 0) and (bit.bxor(a, result) ~= 0))
    return bit.band(result, 0xFFFF)
end

Processor.sub16 = function(self, a, b)
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
        local regs = {
            AX = 0, BX = 0, CX = 0, DX = 0,
            SI = 0, DI = 0, BP = 0, SP = 0xFFFF,
            IP = 0, FLAGS = 0
        }
        
        local env = {
            MOV = function(dest, src)
                coroutine.yield()
                self:applyLoadDelay()
                regs[dest] = src and bit.band(src, 0xFFFF) or regs.AX
            end,

            ADD = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                return self:add16(a or regs.AX, b or 0)
            end,

            SUB = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                return self:sub16(a or regs.AX, b or 0)
            end,

            AND = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
                return bit.band(a or regs.AX, b or 0xFFFF)
            end,

            OR = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
                return bit.bor(a or regs.AX, b or 0xFFFF)
            end,

            XOR = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
                return bit.bxor(a or regs.AX, b or 0xFFFF)
            end,

            NOT = function(a)
                coroutine.yield()
                self:applyLoadDelay()
                return bit.bnot(a or regs.AX) % 0x10000
            end,

            SHL = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                return bit.lshift(a or regs.AX, b or 1) % 0x10000
            end,

            SHR = function(a, b)
                coroutine.yield()
                self:applyLoadDelay()
                return bit.rshift(a or regs.AX, b or 1) % 0x10000
            end,

            LDA = function(v)
                coroutine.yield()
                self:applyLoadDelay()
                regs.AX = v
            end,
            STA = function(a)
                coroutine.yield()
                self:applyLoadDelay()
                self.motherboard:writeMemory(a, regs.AX)
            end,
            LDX = function(v)
                coroutine.yield()
                self:applyLoadDelay()
                regs.BX = v
            end,
            LDY = function(v)
                coroutine.yield()
                self:applyLoadDelay()
                regs.CX = v
            end,
            STX = function(a)
                coroutine.yield()
                self:applyLoadDelay()
                self.motherboard:writeMemory(a, regs.BX)
            end,
            STY = function (a)
                coroutine.yield()
                self:applyLoadDelay()
                self.motherboard:writeMemory(a, regs.CX)
            end,

            getReg = function(name)
                coroutine.yield()
                return regs[name] or 0
            end,
            setReg = function(name, value)
                coroutine.yield()
                regs[name] = value
            end,

            DRW = function(x, y, r, g, b) coroutine.yield() return self:DRW(x, y, r, g, b) end,
            DTX = function(x, y, text, color, scale) coroutine.yield() return self:DTX(x, y, text, color, scale) end,
            DRE = function(x, y, width, height, color) coroutine.yield() return self:DRE(x, y, width, height, color) end,
            DRM = function(x, y, data) coroutine.yield() return self:DRM(x, y, data) end,
            SLEEP = function(s) return self:SLEEP(s) end,

            read = function(addr) coroutine.yield() return self.motherboard:readMemory(addr) end,
            write = function(addr, value) coroutine.yield() return self.motherboard:writeMemory(addr, value) end,
            print = function(...) coroutine.yield() print(...) end,
            pcall = function(...) coroutine.yield() return pcall(...) end
        }

        env.A = function() coroutine.yield() return regs.AX end
        env.X = function() coroutine.yield() return regs.BX end
        env.Y = function() coroutine.yield() return regs.CX end
        env.SR = function() coroutine.yield() return regs.FLAGS end
        env.SP = function() coroutine.yield() return regs.SP end

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
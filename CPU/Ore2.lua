local bit = require("bit")

local ProcessorCore = {
    model = "Ore Core",
    version = "1.0",

    registers = {
        AX = 0,  -- 16-bit accumulator
        BX = 0,  -- Base register
        CX = 0,  -- Counter
        DX = 0,  -- Data
        SI = 0,  -- Source Index
        DI = 0,  -- Destination Index
        BP = 0,  -- Base Pointer
        SP = 0xFFFF,  -- Stack Pointer (initialized to stack top)
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

    currentThread = 1,
    threads = {},
}

function ProcessorCore:init()
    self.gpu = nil
    for k, v in pairs(self.registers) do
        self.registers[k] = 0
    end
    self.registers.SP = 0xFFFF
end

function ProcessorCore:applyLoadDelay()
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.1
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end
end

function ProcessorCore:setFlag(flag, value)
    if value then
        self.registers.FLAGS = bit.bor(self.registers.FLAGS, flag)
    else
        self.registers.FLAGS = bit.band(self.registers.FLAGS, bit.bnot(flag))
    end
end

function ProcessorCore:getFlag(flag)
    return bit.band(self.registers.FLAGS, flag) ~= 0
end

function ProcessorCore:add16(a, b)
    local result = a + b
    self:setFlag(self.FLAGS_MASK.CARRY, result > 0xFFFF)
    self:setFlag(self.FLAGS_MASK.ZERO, bit.band(result, 0xFFFF) == 0)
    self:setFlag(self.FLAGS_MASK.SIGN, bit.band(result, 0x8000) ~= 0)
    self:setFlag(self.FLAGS_MASK.OVERFLOW, (bit.bxor(a, b) == 0) and (bit.bxor(a, result) ~= 0))
    return bit.band(result, 0xFFFF)
end

function ProcessorCore:sub16(a, b)
    local result = a - b
    self:setFlag(self.FLAGS_MASK.CARRY, a < b)
    self:setFlag(self.FLAGS_MASK.ZERO, bit.band(result, 0xFFFF) == 0)
    self:setFlag(self.FLAGS_MASK.SIGN, bit.band(result, 0x8000) ~= 0)
    self:setFlag(self.FLAGS_MASK.OVERFLOW, (bit.bxor(a, b) ~= 0) and (bit.bxor(a, result) ~= 0))
    return bit.band(result, 0xFFFF)
end

function ProcessorCore:DRW(x, y, r, g, b)
    self:applyLoadDelay()
    if self.gpu then
        self.gpu:drawPixel(x, y, {r, g, b})
    end
end

function ProcessorCore:DTX(x, y, text, color, scale)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawText(x, y, text, color, scale)
        end
    end
end

function ProcessorCore:DRE(x, y, width, height, color)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawRectangle(x, y, width, height, color)
        end
    end
end

function ProcessorCore:DRM(x, y, data)
    self:applyLoadDelay()
    if self.gpu then
        if self.gpu.driver == "Unakoda" then
            self.gpu:drawImage(x, y, data)
        end
    end
end

function ProcessorCore:SLEEP(seconds)
    self:applyLoadDelay()
    local start = self.lastTime or love.timer.getTime()
    while (love.timer.getTime() - start) < seconds do
        coroutine.yield()
    end
end

function ProcessorCore:addThread(func)
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
    return true, co
end

local OreDualCore = {
    model = "Ore2DC",
    version = "1.0",
    
    cores = {},
    currentCore = 1,

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
    thermalThrottle = false,
    
    lastTime = 0,
    motherboard = nil,
    cpuLoad = 0,
    performanceFactor = 1,
    threadLoad = {},
    input_current = 20,
}

function OreDualCore:init()
    self.cores[1] = setmetatable({}, {__index = ProcessorCore})
    self.cores[2] = setmetatable({}, {__index = ProcessorCore})
    self.cores[1]:init()
    self.cores[2]:init()
    
    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
    self.cpuLoad = 0
    self.performanceFactor = 1
end

function OreDualCore:setGPU(gpu)
    self.gpu = gpu
    self.cores[1].gpu = gpu
    self.cores[2].gpu = gpu
end

function OreDualCore:setMotherboard(motherboard)
    self.motherboard = motherboard
    self.cores[1].motherboard = motherboard
    self.cores[2].motherboard = motherboard
end

function OreDualCore:updatePerformance()
    local thermalFactor = 1 - math.min(1, self.TPD / self.maxTPD)
    
    for _, core in ipairs(self.cores) do
        local loadFactor = 1 - math.min(1, #core.threads / 32)
        core.performanceFactor = math.min(loadFactor, thermalFactor)
        
        if self.cpuLoad > 80 then
            core.performanceFactor = core.performanceFactor * 0.8
        end
        
        core.performanceFactor = math.max(0.1, core.performanceFactor)
    end

    self.performanceFactor = (self.cores[1].performanceFactor + self.cores[2].performanceFactor) / 2
end

function OreDualCore:updateCpuLoad()
    local activeThreads = 0
    for _, core in ipairs(self.cores) do
        for _, thread in ipairs(core.threads) do
            if coroutine.status(thread) ~= "dead" then
                activeThreads = activeThreads + 1
            end
        end
    end
    
    local maxThreads = 64
    local clockFactor = self.currentClockSpeed / self.baseClockSpeed
    self.cpuLoad = math.min(100, (activeThreads / maxThreads) * 100 * clockFactor)
end

function OreDualCore:addThread(func)
    local coreToUse = (#self.cores[1].threads <= #self.cores[2].threads) and 1 or 2
    
    if self:calculatePotentialPower(#self.cores[1].threads + #self.cores[2].threads + 1) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false
    end
    
    local success, co = self.cores[coreToUse]:addThread(func)
    if success then
        self.threadLoad[co] = 0
        self:updatePowerUsage()
        self:updateCpuLoad()
    end
    return success, co
end

function OreDualCore:removeThread(index)
    if index <= #self.cores[1].threads then
        table.remove(self.cores[1].threads, index)
    else
        local core2Index = index - #self.cores[1].threads
        table.remove(self.cores[2].threads, core2Index)
    end
    self:updatePowerUsage()
end

function OreDualCore:searchThread(co)
    for i = 1, #self.cores[1].threads do
        if self.cores[1].threads[i] == co then
            return i, 1
        end
    end
    for i = 1, #self.cores[2].threads do
        if self.cores[2].threads[i] == co then
            return i - #self.cores[1].threads, 2
        end
    end
end

function OreDualCore:calculatePotentialPower(numThreads)
    local load = numThreads / 32
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function OreDualCore:updatePowerUsage()
    local totalThreads = #self.cores[1].threads + #self.cores[2].threads
    local load = totalThreads / 32
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

function OreDualCore:updateTPD()
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

function OreDualCore:autoBoostClock()
    if not self.autoBoost then return end

    if self.thermalThrottle then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed - 20
        )
        return
    end

    local totalThreads = #self.cores[1].threads + #self.cores[2].threads
    local load = totalThreads / 32
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


function OreDualCore:tick()
    self:updatePerformance()
    self:updateCpuLoad()
    
    if self.performanceFactor < 0.5 then
        local delay = (0.5 - self.performanceFactor) * 0.05
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end

    for _, core in ipairs(self.cores) do
        if #core.threads > 0 then
            local thread = core.threads[core.currentThread]
            if not thread then
                core.currentThread = core.currentThread % #core.threads + 1
                goto continue
            end

            if coroutine.status(thread) == "dead" then
                table.remove(core.threads, core.currentThread)
                self.threadLoad[thread] = nil
                self:updatePowerUsage()
                self:updateCpuLoad()
                goto continue
            end

            self.threadLoad[thread] = (self.threadLoad[thread] or 0) + 1
            
            local ok, err = coroutine.resume(thread)
            if not ok then
                print("Thread error:", err)
                table.remove(core.threads, core.currentThread)
                self.threadLoad[thread] = nil
                self:updatePowerUsage()
                self:updateCpuLoad()
            end

            core.currentThread = core.currentThread % #core.threads + 1
        end
        ::continue::
    end
end

function OreDualCore:update(dt)
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

        if OreDualCore.updateComponents then
            OreDualCore.updateComponents(dt)
        end
    end
end

function OreDualCore:getInfo()
    local core1Threads = #self.cores[1].threads
    local core2Threads = #self.cores[2].threads
    local activeThreads = self:countActiveThreads()
    
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
        activeThreads = activeThreads,
        core1Threads = core1Threads,
        core2Threads = core2Threads,
        autoBoost = self.autoBoost,
        thermalThrottle = self.thermalThrottle,
        cpuLoad = self.cpuLoad,
        performanceFactor = self.performanceFactor,
        threadLoads = self:getThreadLoads()
    }
end

function OreDualCore:countActiveThreads()
    local count = 0
    for _, core in ipairs(self.cores) do
        for _, thread in ipairs(core.threads) do
            if coroutine.status(thread) ~= "dead" then
                count = count + 1
            end
        end
    end
    return count
end

function OreDualCore:getThreadLoads()
    local loads = {}
    for thread, load in pairs(self.threadLoad) do
        if type(thread) == "thread" and coroutine.status(thread) ~= "dead" then
            loads[#loads+1] = {
                thread = tostring(thread),
                load = load,
                core = (self:threadBelongsToCore(thread, 1) and 1 or 2)
            }
        end
    end
    return loads
end

function OreDualCore:threadBelongsToCore(thread, coreIndex)
    for _, t in ipairs(self.cores[coreIndex].threads) do
        if t == thread then
            return true
        end
    end
    return false
end

return OreDualCore
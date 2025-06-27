--[[
BETA процессор
В релизе будет удален

Предназначен чисто для тестов


Уникальная 500 ядерная мощь
]]

local bit = require("bit")

local ProcessorCore = {
    model = "Super Core",
    version = "1.0",

    registers = {
        AX = 0,
        BX = 0,
        CX = 0,
        DX = 0,
        SI = 0,
        DI = 0,
        BP = 0,
        SP = 0xFFFF,
        IP = 0,
        FLAGS = 0,
    },

    FLAGS_MASK = {
        CARRY     = 0x0001,
        ZERO      = 0x0002,
        SIGN      = 0x0004,
        OVERFLOW  = 0x0008,
        INTERRUPT = 0x0020,
        DIRECTION = 0x0400, 
    },

    currentThread = 1,
    threads = {},
    gpu = nil,
    motherboard = nil,
    performanceFactor = 1,
}

function ProcessorCore:init()
    self.gpu = nil
    for k, v in pairs(self.registers) do
        self.registers[k] = 0
    end
    self.registers.SP = 0xFFFF 
    self.threads = {}
end

function ProcessorCore:applyLoadDelay()
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.04
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do 
            coroutine.yield()
        end
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

function ProcessorCore:updatePerformanceFactor(cpuLoad, thermalFactor)
    local maxThreadsPerCore = 32
    local loadFactor = 1 - math.min(1, #self.threads / maxThreadsPerCore)

    self.performanceFactor = math.min(loadFactor, thermalFactor)

    if cpuLoad > 80 then
        self.performanceFactor = self.performanceFactor * 0.8
    end

    self.performanceFactor = math.max(0.1, self.performanceFactor)
end

function ProcessorCore:addThread(func)
    local co = coroutine.create(function()
        local arch = require("CPU.arch.16") 
        local env = arch(self)

        setmetatable(env, {__index = _G}) 
        setfenv(func, env)

        func() 
    end)

    table.insert(self.threads, co)
    return true, co
end

local Processor = {
    model = "Zero5000 PRO MAX",
    version = "1.0",
    
    cores = {},
    currentCore = 1,
    countCores = 500,

    baseClockSpeed = 5500,
    currentClockSpeed = 5500,
    clockAccumulator = 0,

    autoBoost = true,
    maxClockSpeed = 6000,
    minClockSpeed = 1000,
    boostThreshold = 0.7,
    throttleThreshold = 0.9,
    
    powerUsage = 0,
    maxPowerUsage = 500,
    TPD = 0,
    maxTPD = 100,
    coolingRate = 0.2,
    heatingRate = 0.9,
    thermalThrottle = false,
    
    lastTime = 0,
    motherboard = nil,

    cpuLoad = 0,
    performanceFactor = 1,
    threadLoad = {},
    input_current = 500,
}

function Processor:init()
    for i = 1, self.countCores, 1 do
        self.cores[i] = setmetatable({}, {__index = ProcessorCore})
        self.cores[i]:init()
    end

    self.currentClockSpeed = self.baseClockSpeed
    self.powerUsage = 0
    self.TPD = 0
    self.thermalThrottle = false
    self.gpu = nil
    self.cpuLoad = 0
    self.performanceFactor = 1
    self.input_current = self.maxPowerUsage
end

function Processor:setGPU(gpu)
    self.gpu = gpu
    for i = 1, self.countCores, 1 do
        self.cores[i].gpu = gpu
    end
end

function Processor:setMotherboard(motherboard)
    self.motherboard = motherboard
    for i = 1, self.countCores, 1 do
        self.cores[i].motherboard = motherboard
    end
end

function Processor:updateCpuLoad()
    local activeThreads = 0
    for _, core in ipairs(self.cores) do
        for _, thread in ipairs(core.threads) do
            if coroutine.status(thread) ~= "dead" then
                activeThreads = activeThreads + 1
            end
        end
    end
    
    local maxThreads = 32 * self.countCores 
    local clockFactor = self.currentClockSpeed / self.baseClockSpeed
    self.cpuLoad = math.min(100, (activeThreads / maxThreads) * 100 * clockFactor)
end

function Processor:updatePerformance()
    local thermalFactor = 1 - math.min(1, self.TPD / self.maxTPD)
    local totalPerformanceFactor = 0

    for _, core in ipairs(self.cores) do
        core:updatePerformanceFactor(self.cpuLoad, thermalFactor)
        totalPerformanceFactor = totalPerformanceFactor + core.performanceFactor
    end

    self.performanceFactor = totalPerformanceFactor / #self.cores
end

function Processor:addThread(func)
    local minThreads = math.huge
    local bestCore = 1
    for i = 1, self.countCores do
        local threadCount = #self.cores[i].threads
        if threadCount < minThreads then
            minThreads = threadCount
            bestCore = i
        end
    end

    local totalThreads = self:countActiveThreads()

    if self:calculatePotentialPower(totalThreads + 1) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false, nil
    end

    local success, co = self.cores[bestCore]:addThread(func)
    if success then
        self.threadLoad[co] = 0
        self:updatePowerUsage()
        self:updateCpuLoad()
    end
    return success, co
end

function Processor:removeThread(index)
    local totalThreadsChecked = 0
    for coreIndex, core in ipairs(self.cores) do
        local numThreadsInCore = #core.threads
        if index <= totalThreadsChecked + numThreadsInCore then
            local relativeIndex = index - totalThreadsChecked
            local removedThread = table.remove(core.threads, relativeIndex)
            if removedThread then
                self.threadLoad[removedThread] = nil
                self:updatePowerUsage()
                self:updateCpuLoad()
            end
            return
        else
            totalThreadsChecked = totalThreadsChecked + numThreadsInCore
        end
    end
end

function Processor:searchThread(co)
    local globalIndex = 0
    for coreIdx = 1, #self.cores, 1 do
        for i = 1, #self.cores[coreIdx].threads do
            globalIndex = globalIndex + 1
            if self.cores[coreIdx].threads[i] == co then
                return globalIndex, coreIdx
            end
        end
    end
    return nil, nil
end

function Processor:calculatePotentialPower(numThreads)
    local maxThreads = 32 * self.countCores
    local load = numThreads / maxThreads
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function Processor:updatePowerUsage()
    local totalThreads = self:countActiveThreads()
    local maxThreads = 32 * self.countCores
    local load = totalThreads / maxThreads
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

    local totalThreads = self:countActiveThreads()
    local maxThreads = 32 * self.countCores
    local load = totalThreads / maxThreads
    
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

function Processor:update(dt)
    if self.input_current < math.min(self.powerUsage, self.maxPowerUsage) then 
        self.input_current = 0 
        return
    end
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
    local threads = 0
    for i = 1, #self.cores, 1 do
        threads = threads + #self.cores[i].threads
    end
    local activeThreads = self:countActiveThreads()
    
    return {
        cores = #self.cores,
        clockSpeed = self.currentClockSpeed,
        baseClockSpeed = self.baseClockSpeed,
        maxClockSpeed = self.maxClockSpeed,
        minClockSpeed = self.minClockSpeed,
        powerUsage = self.powerUsage,
        maxPowerUsage = self.maxPowerUsage,
        TPD = self.TPD,
        maxTPD = self.maxTPD,
        threads = threads,
        activeThreads = activeThreads,
        autoBoost = self.autoBoost,
        thermalThrottle = self.thermalThrottle,
        cpuLoad = self.cpuLoad,
        performanceFactor = self.performanceFactor,
        threadLoads = self:getThreadLoads()
    }
end

function Processor:countActiveThreads()
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

function Processor:getThreadLoads()
    local loads = {}
    for thread, load in pairs(self.threadLoad) do
        if type(thread) == "thread" and coroutine.status(thread) ~= "dead" then
            local _, coreId = self:searchThread(thread)
            loads[#loads+1] = {
                thread = tostring(thread),
                load = load,
                core = coreId or "N/A"
            }
        end
    end
    return loads
end

function Processor:threadBelongsToCore(thread, coreIndex)
    if not self.cores[coreIndex] then return false end
    for _, t in ipairs(self.cores[coreIndex].threads) do
        if t == thread then
            return true
        end
    end
    return false
end

return Processor
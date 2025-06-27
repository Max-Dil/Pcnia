local arch = require("CPU.arch.8")
local bit = require("bit")

local ProcessorCore = {
    model = "Zero2",
    version = "1.1",

    currentThread = 1,
    threads = {},   -- Threads (coroutines)
}

function ProcessorCore:init()
    self.gpu = nil
end

function ProcessorCore:applyLoadDelay()
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.08
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do coroutine.yield() end
    end
end
function ProcessorCore:updatePerformanceFactor(cpuLoad, thermalFactor)
    local loadFactor = 1 - math.min(1, #self.threads / 8)
    self.performanceFactor = math.min(loadFactor, thermalFactor)

    if cpuLoad > 80 then
        self.performanceFactor = self.performanceFactor * 0.8
    end
    
    self.performanceFactor = math.max(0.1, self.performanceFactor)
end

function ProcessorCore:addThread(func)
    local co = coroutine.create(function()
        local env = arch(self)

        setmetatable(env, {__index = _G})
        setfenv(func, env)

        func()
    end)

    table.insert(self.threads, co)
    return true, co
end

-- Dual-core processor implementation
local DualCoreProcessor = {
    model = "Zero2DC",
    version = "1.0",
    
    cores = {},
    currentCore = 1,
    
    -- Shared properties
    baseClockSpeed = 10,
    currentClockSpeed = 10,
    clockAccumulator = 0,
    
    autoBoost = true,
    maxClockSpeed = 20,
    minClockSpeed = 1,
    boostThreshold = 0.7,
    throttleThreshold = 0.9,
    
    powerUsage = 0,
    maxPowerUsage = 10,
    TPD = 0,
    maxTPD = 4,
    coolingRate = 0.2,
    heatingRate = 0.6,
    thermalThrottle = false,
    
    lastTime = 0,

    motherboard = nil,

    cpuLoad = 0,
    performanceFactor = 1,
    threadLoad = {},

    input_current = 15,
}

function DualCoreProcessor:init()
    self.cores[1] = setmetatable({}, {__index = ProcessorCore})
    self.cores[2] = setmetatable({}, {__index = ProcessorCore})
    self.cores[1].threads = {}
    self.cores[2].threads = {}
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

function DualCoreProcessor:updateCpuLoad()
    local activeThreads = 0
    for _, core in ipairs(self.cores) do
        for _, thread in ipairs(core.threads) do
            if coroutine.status(thread) ~= "dead" then
                activeThreads = activeThreads + 1
            end
        end
    end
    
    local maxThreads = 32
    local clockFactor = self.currentClockSpeed / self.baseClockSpeed
    self.cpuLoad = math.min(100, (activeThreads / maxThreads) * 100 * clockFactor)
end

function DualCoreProcessor:updatePerformance()
    local thermalFactor = 1 - math.min(1, self.TPD / self.maxTPD)

    for _, core in ipairs(self.cores) do
        core:updatePerformanceFactor(self.cpuLoad, thermalFactor)
    end

    self.performanceFactor = (self.cores[1].performanceFactor + self.cores[2].performanceFactor) / 2
end

function DualCoreProcessor:addThread(func)
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

function DualCoreProcessor:removeThread(index)
    if index <= #self.cores[1].threads then
        table.remove(self.cores[1].threads, index)
    else
        local core2Index = index - #self.cores[1].threads
        table.remove(self.cores[2].threads, core2Index)
    end
    self:updatePowerUsage()
end

function DualCoreProcessor:searchThread(co)
    for i = 1, #self.cores[1].threads do
        if self.cores[1].threads[i] == co then
            return i, 1
        end
    end
    for i = 1, #self.cores[2].threads do
        if self.cores[2].threads[i] == co then
            return #self.cores[1].threads + i, 2
        end
    end
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

function DualCoreProcessor:update(dt)
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

        if DualCoreProcessor.updateComponents then
            DualCoreProcessor.updateComponents(dt)
        end
    end
end

function DualCoreProcessor:getInfo()
    local core1Threads = #self.cores[1].threads
    local core2Threads = #self.cores[2].threads
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

function DualCoreProcessor:countActiveThreads()
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

function DualCoreProcessor:getThreadLoads()
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

function DualCoreProcessor:threadBelongsToCore(thread, coreIndex)
    for _, t in ipairs(self.cores[coreIndex].threads) do
        if t == thread then
            return true
        end
    end
    return false
end

return DualCoreProcessor
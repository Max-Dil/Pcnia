--[[
Zero5000

Лимитированный 8 битный процессор ранга Gold
Огромный потенциал, идеальный серверный процессор.
За счет огромного количества ядер идеально подходит для многопоточных приложений.

Чтобы раскрыть его потенциал нужен блок питания минимум на 1100W
Так его использование на полной мощности будет не всем по карманам.
]]

local arch = require("CPU.arch.8")
local bit = require("bit")

local ProcessorCore = {
    model = "Zero5000",
    version = "1.1",

    currentThread = 1,
    threads = {},
}

function ProcessorCore:init()
    self.gpu = nil
end

function ProcessorCore:applyLoadDelay()
    if self.performanceFactor < 0.3 then
        local delay = (1 - self.performanceFactor) * 0.08
        local start = love.timer.getTime()
        while (love.timer.getTime() - start) < delay do end
    end
end
function ProcessorCore:updatePerformanceFactor(cpuLoad, thermalFactor)
    local loadFactor = 1 - math.min(1, #self.threads / 64)
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

local Processor = {
    model = "Zero5000",
    version = "1.0",
    
    cores = {},
    currentCore = 1,
    countCores = 200,

    baseClockSpeed = 10,
    currentClockSpeed = 10,
    clockAccumulator = 0,
    
    autoBoost = true,
    maxClockSpeed = 20,
    minClockSpeed = 1,
    boostThreshold = 0.7,
    throttleThreshold = 0.9,
    
    powerUsage = 0,
    maxPowerUsage = 1000,
    TPD = 0,
    maxTPD = 400,
    coolingRate = 0.2,
    heatingRate = 0.6,
    thermalThrottle = false,
    
    lastTime = 0,

    motherboard = nil,

    cpuLoad = 0,
    performanceFactor = 1,
    threadLoad = {},

    input_current = 1000,
}

function Processor:init()
    for i = 1, self.countCores, 1 do
        self.cores[i] = setmetatable({}, {__index = ProcessorCore})
        self.cores[i].threads = {}
        self.cores[i]:init()
    end

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
    
    local maxThreads = 8 * self.countCores
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

    local totalThreads = 0
    for i = 1, self.countCores do
        totalThreads = totalThreads + #self.cores[i].threads
    end

    if self:calculatePotentialPower(totalThreads + 1) > self.maxPowerUsage then
        print("Warning: Adding this thread would exceed power limits!")
        return false
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
    local totalThreads = 0
    for coreIndex, core in ipairs(self.cores) do
        local numThreadsInCore = #core.threads
        if index <= totalThreads + numThreadsInCore then
            local relativeIndex = index - totalThreads
            table.remove(core.threads, relativeIndex)
            self:updatePowerUsage()
            return
        else
            totalThreads = totalThreads + numThreadsInCore
        end
    end
end

function Processor:searchThread(co)
    local globalIndex = 0
    for core = 1, #self.cores, 1 do
        for i = 1, #self.cores[core].threads do
            globalIndex = globalIndex + 1
            if self.cores[core].threads[i] == co then
                return globalIndex, core
            end
        end
    end
    return nil
end

function Processor:calculatePotentialPower(numThreads)
    local load = numThreads / (8 * self.countCores)
    return self.maxPowerUsage * load * (self.currentClockSpeed / self.baseClockSpeed)
end

function Processor:updatePowerUsage()
    local totalThreads = self:countActiveThreads()
    local load = totalThreads / (8 * self.countCores)
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

    local totalThreads = 0
    for i = 1, #self.cores, 1 do
        totalThreads = totalThreads + #self.cores[i].threads
    end
    local load = totalThreads / (8 * self.countCores)
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
    for i = 1, #self.cores, 1 do
        local core = self.cores[i]
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
            loads[#loads+1] = {
                thread = tostring(thread),
                load = load,
                core = (self:threadBelongsToCore(thread, 1) and 1 or 2)
            }
        end
    end
    return loads
end

function Processor:threadBelongsToCore(thread, coreIndex)
    for _, t in ipairs(self.cores[coreIndex].threads) do
        if t == thread then
            return true
        end
    end
    return false
end

return Processor
local resourceMonitorApp = {
    name = "ResM",
    version = "1.18",
    main = "main",
    iconText = "RM",
    backgroundJob = true,
    icon = json.decode('[[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[255,60,60],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,80,100],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[255,60,60],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[255,60,60],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[80,80,100],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,80,100],[10,15,25],[10,15,25],[60,255,60],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,80,100],[10,15,25],[60,255,60],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,80,100],[60,255,60],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,80,100],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[150,150,160],[150,150,160],[150,150,160],[150,150,160],[150,150,160]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[60,255,60],[80,80,100],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[60,255,60],[30,40,70],[180,180,190],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[60,255,60],[20,80,20],[80,80,100],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[60,255,60],[30,40,70],[180,180,190],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[60,255,60],[20,80,20],[80,80,100],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[60,255,60],[30,40,70],[180,180,190],[10,15,25],[255,60,60],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[80,20,20],[60,255,60],[20,80,20],[80,80,100],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[20,80,20],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[80,80,100],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[10,15,25],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[180,180,190],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]],[[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70],[30,40,70]]]'),
    iconTextColor = {255, 255, 255},
    --system = true,
    scripts = {
        main = [[
local updateInterval = 3
local lastUpdate = 0
local showDetails = false
local selectedTab = 1
local tabs = {"CPU", "RAM", "GPU", "Disk", "PSU"}
local cpuHistory = {}
local ramHistory = {}
local gpuHistory = {}
local maxHistory = 60
local networkStats = {download = 0, upload = 0}
local prevNetworkStats = {download = 0, upload = 0}

for i = 1, maxHistory do
    cpuHistory[i] = 0
    ramHistory[i] = 0
    gpuHistory[i] = 0
end

local function drawTabBar()
    local tabWidth = MONITOR.resolution.width / #tabs
    for i, tab in ipairs(tabs) do
        local color = {70, 70, 70}
        if i == selectedTab then
            color = {100, 100, 100}
        end
        
        DRE((i-1)*tabWidth, 30, tabWidth, 30, color)
        DTX((i-1)*tabWidth + tabWidth/2 - (#tab*3), 40, tab, {255, 255, 255}, 1)
    end
end

local function drawCPUInfo()
    local info = CPU:getInfo()
    local usage = info.cpuLoad
    
    table.remove(cpuHistory, 1)
    table.insert(cpuHistory, usage)
    
    DTX(10, 70, "Model: "..CPU.model, {255, 255, 255}, 1)
    DTX(10, 90, "Cores: "..info.cores or 1, {255, 255, 255}, 1)
    DTX(10, 110, "Clock: "..string.format("%.2f", info.clockSpeed/1000).." GHz / ".. (info.maxClockSpeed/1000) .. " Ghz" , {255, 255, 255}, 1)
    DTX(10, 130, "Usage: "..usage.."%", {255, 255, 255}, 1)
    DTX(120, 70, "Temperature: "..(info.TPD or "N/A").."°C", {255, 255, 255}, 1)

    local graphWidth = MONITOR.resolution.width - 20
    local graphHeight = 100
    local graphX = 10
    local graphY = 160
    
    DRE(graphX, graphY, graphWidth, graphHeight, {40, 40, 40})
    
    for i = 1, #cpuHistory do
        local value = cpuHistory[i]
        local barHeight = math.floor(graphHeight * value / 100)
        local barX = graphX + (i-1)*(graphWidth/maxHistory)
        local barWidth = math.floor(graphWidth/maxHistory) - 1
        
        local color = {50, 200, 50}
        if value > 70 then color = {200, 200, 50} end
        if value > 90 then color = {200, 50, 50} end
        
        DRE(barX, graphY + graphHeight - barHeight, barWidth, barHeight, color)
    end
    
    if showDetails then
        DTX(10, graphY + graphHeight + 30, "Auto boost: "..tostring(info.autoBoost), {255, 255, 255}, 1)
    end
end

local function drawRAMInfo()
    local info = RAM:getInfo()
    local used = info.usedMemory
    local total = info.capacity
    local usage = math.floor((used / total) * 100)

    table.remove(ramHistory, 1)
    table.insert(ramHistory, usage)

    DTX(10, 70, "Total: "..string.format("%.1f", total/1024).." MB", {255, 255, 255}, 1)
    DTX(10, 90, "Used: "..string.format("%.1f", used/1024).." MB", {255, 255, 255}, 1)
    DTX(10, 110, "Free: "..string.format("%.1f", (total-used)/1024).." MB", {255, 255, 255}, 1)
    DTX(10, 130, "Usage: "..usage.."%", {255, 255, 255}, 1)
    DTX(120, 70, "Temperature: "..(info.temperature  or "N/A").."°C", {255, 255, 255}, 1)

    local barWidth = MONITOR.resolution.width - 20
    local barHeight = 20
    local barX = 10
    local barY = 160
    
    DRE(barX, barY, barWidth, barHeight, {40, 40, 40})
    DRE(barX, barY, barWidth * usage / 100, barHeight, {50, 50, 200})

    local graphWidth = MONITOR.resolution.width - 20
    local graphHeight = 80
    local graphX = 10
    local graphY = 190
    
    DRE(graphX, graphY, graphWidth, graphHeight, {40, 40, 40})
    
    for i = 1, #ramHistory do
        local value = ramHistory[i]
        local barHeight = math.floor(graphHeight * value / 100)
        local barX = graphX + (i-1)*(graphWidth/maxHistory)
        local barWidth = math.floor(graphWidth/maxHistory) - 1
        
        DRE(barX, graphY + graphHeight - barHeight, barWidth, barHeight, {50, 50, 200})
    end
    
    if showDetails then
        DTX(10, graphY + graphHeight + 20, "frequency: "..(info.frequency or "N/A").." MHz", {255, 255, 255}, 1)
        DTX(10, graphY + graphHeight + 40, "timings: "..(info.timings or "N/A"), {255, 255, 255}, 1)
    end
end

local function drawGPUInfo()
    local info = GPU:getInfo()
    local usage = info.utilization.core

    table.remove(gpuHistory, 1)
    table.insert(gpuHistory, usage)

    DTX(10, 70, "Model: "..info.model, {255, 255, 255}, 1)
    DTX(10, 90, "VRAM: "..string.format("%.1f", info.memory_usage[1]/1024).." MB / " .. info.memory_usage[2] / 1024 .. " MB", {255, 255, 255}, 1)
    DTX(10, 110, "Resolution: "..info.resolution[1].."x"..info.resolution[2], {255, 255, 255}, 1)
    DTX(10, 130, "Usage: "..usage.."%", {255, 255, 255}, 1)
    DTX(120, 70, "Temperature: "..(info.temperature[1] or "N/A").."°C", {255, 255, 255}, 1)

    local graphWidth = MONITOR.resolution.width - 20
    local graphHeight = 100
    local graphX = 10
    local graphY = 160
    
    DRE(graphX, graphY, graphWidth, graphHeight, {40, 40, 40})
    
    for i = 1, #gpuHistory do
        local value = gpuHistory[i]
        local barHeight = math.floor(graphHeight * value / 100)
        local barX = graphX + (i-1)*(graphWidth/maxHistory)
        local barWidth = math.floor(graphWidth/maxHistory) - 1
        
        local color = {200, 50, 200} -- Purple
        if value > 70 then color = {200, 100, 200} end
        if value > 90 then color = {200, 150, 200} end
        
        DRE(barX, graphY + graphHeight - barHeight, barWidth, barHeight, color)
    end
    
    if showDetails then
    end
end

local function drawDiskInfo()
    local info = HDD:getInfo()
    
    DTX(10, 70, "Model: "..info.model, {255, 255, 255}, 1)
    DTX(10, 90, "Capacity: "..string.format("%.1f", info.capacity/1024).." GB", {255, 255, 255}, 1)
    DTX(10, 110, "Used: "..string.format("%.1f", info.usedSpace/1024/1024).." GB", {255, 255, 255}, 1)
    DTX(10, 130, "Free: "..string.format("%.1f", info.freeSpace/1024/1024).." GB", {255, 255, 255}, 1)
    DTX(150, 70, "Temperature: "..(info.temperature or "N/A").."°C", {255, 255, 255}, 1)

    local barWidth = MONITOR.resolution.width - 20
    local barHeight = 20
    local barX = 10
    local barY = 160
    
    local usage = info.utilization
    
    DRE(barX, barY, barWidth, barHeight, {40, 40, 40})
    DRE(barX, barY, barWidth * usage / 100, barHeight, {200, 150, 50})
    
    if showDetails then
        DTX(10, barY + 30, "Errors: "..info.errors, {255, 255, 255}, 1)
    end
end

local function drawPSUInfo()
    local info = PSU:getInfo()
    
    DTX(10, 70, "Model: "..info.model, {255, 255, 255}, 1)
    DTX(10, 90, "Temperature: "..string.format("%.1f", info.temperature).."°C", {255, 255, 255}, 1)
    DTX(10, 110, "Fan Speed: "..info.fanSpeed.."%", {255, 255, 255}, 1)
    DTX(10, 130, "Efficiency: "..string.format("%.1f", info.efficiency).."%", {255, 255, 255}, 1)
    DTX(10, 150, "Available Power: "..string.format("%.1f", info.availablePower).."W", {255, 255, 255}, 1)

    local yPos = 180
    DTX(10, yPos, "Voltage Rails:", {200, 200, 100}, 1)
    yPos = yPos + 20
    
    for rail, current in pairs(info.rails) do
        DTX(20, yPos, rail..": "..string.format("%.2f", current).."A", {255, 255, 255}, 1)
        yPos = yPos + 20
    end

    local graphWidth = MONITOR.resolution.width - 20
    local graphHeight = 60
    local graphX = 10
    local graphY = yPos + 20
    
    DRE(graphX, graphY, graphWidth, graphHeight, {40, 40, 40})
    
    if showDetails then
        DTX(10, graphY + graphHeight + 20, "Overload Protection: "..tostring(PSU.overloadProtection), {255, 255, 255}, 1)
        if PSU.is_lomka then
            DTX(10, graphY + graphHeight + 40, "STATUS: CRITICAL FAILURE!", {255, 50, 50}, 1)
        end
    end
end

local function updateDisplay()
    GPU:clear()

    DRE(0, 0, MONITOR.resolution.width, 30, {50, 50, 50})
    DTX(10, 10, "Resource Monitor", {255, 255, 255}, 1)
    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})

    drawTabBar()

    if selectedTab == 1 then
        drawCPUInfo()
    elseif selectedTab == 2 then
        drawRAMInfo()
    elseif selectedTab == 3 then
        drawGPUInfo()
    elseif selectedTab == 4 then
        drawDiskInfo()
    elseif selectedTab == 5 then
        drawPSUInfo()
    end

    local footerY = MONITOR.resolution.height - 20
    DRE(0, footerY, MONITOR.resolution.width, 20, {40, 40, 40})
    DTX(10, footerY + 5, "F1: Toggle Details | F5: Refresh | Update: "..updateInterval.."s", {150, 150, 150}, 1)
end

addEvent("keypressed", function(key)
    if key == "f1" then
        showDetails = not showDetails
    elseif key == "f5" then
        lastUpdate = os.time() - updateInterval
    elseif key == "up" then
        updateInterval = math.min(10, updateInterval + 1)
    elseif key == "down" then
        updateInterval = math.max(1, updateInterval - 1)
    elseif key == "left" then
        selectedTab = math.max(1, selectedTab - 1)
    elseif key == "right" then
        selectedTab = math.min(#tabs, selectedTab + 1)
    end
    
    updateDisplay()
end)

updateDisplay()

while true do
    local currentTime = os.time()
    if currentTime - lastUpdate >= updateInterval then
        lastUpdate = currentTime
        updateDisplay()
    end
    SLEEP(0.001)
end
]]
    }
}

return resourceMonitorApp
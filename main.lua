

--local Processor = require("CPU.Zero1")
local Processor = require("CPU.Zero2")
--local Processor = require("CPU.ZeroUltraMax")
local Alpeg1000 = require("MOTHER.Alpeg1000")
local Enma1 = require("POWER.Enma1")
--local Enma1 = require("POWER.EnmaUltraMax1")
local Swipan = require("COOLER.Swipan")
local Unsa2x10m = require("RAM.Unsa 2x10m")
local Huga = require("MONITOR.Huga")
local Avrora = require("GPU.Avrora")
local Typyka = require("DISK.Typyka")
local font = love.graphics.newFont(14)
_G.love = love

local function drawRect(x, y, width, height, color)
    color = color or {255, 0, 0}
    
    Processor:addThread(function()
        for i = 0, width do
            for j = 0, height do
                DRW(x + i, y + j, color[1], color[2], color[3])

                if width > 5 or height > 5 then
                    SLEEP(0.01)
                end
            end
        end
    end)
end

local function createAnimatedSquare(x, y)
    Processor:addThread(function()
        local size = 20
        local colors = {
            {255, 0, 0},   -- Красный
            {0, 255, 0},   -- Зеленый
            {0, 0, 255},   -- Синий
            {255, 255, 0}, -- Желтый
        }
        
        while true do
            local color = colors[math.random(1, #colors)]

            for i = 0, size-1 do
                for j = 0, size-1 do
                    DRW(x + i, y + j, color[1], color[2], color[3])
                end
            end
            
            SLEEP(1)
            
            for i = 0, size-1 do
                for j = 0, size-1 do
                    DRW(x + i, y + j, 0, 0, 0) 
                end
            end

            x = x + 10
            if x > 300 then
                x = 100
                y = y + 20
                if y > 200 then y = 100 end
            end
            
            SLEEP(0.01)
        end
    end)
end

function love.load()
    Processor:init()
    MB = Alpeg1000:init(Processor)
    Processor.motherboard = MB
    RAM = Unsa2x10m:init(MB)
    Cooler = Swipan:init(Processor, MB)
    MB:attachCooler(Cooler)
    PSU = Enma1:init(MB)
    GPU = Avrora:init(Processor)
    MONITOR = Huga:init(GPU)
    Processor:setGPU(GPU)
    MB.gpu = GPU
    MB.monitor = MONITOR
    HDD = Typyka:init(MB)
    MB:attachStorage(HDD)

--     -- Тестирование HDD
-- HDD:addEventListener("write", function(hdd, address, size)
--     print(string.format("[HDD] Write: addr=%d, size=%d, used=%.2fMB/%.2fMB", 
--         address, size, hdd.usedSpace, hdd.effectiveCapacity))
-- end)

-- HDD:addEventListener("read", function(hdd, address, size)
--     print(string.format("[HDD] Read: addr=%d, size=%d", address, size))
-- end)

-- -- Запись тестовых данных
-- local testData = string.rep("X", 10024) -- 1KB данных
-- for i = 0, 11100 do
--     HDD:write(i * 1024, testData) -- Записываем по 1KB с шагом 1KB
-- end


    -- Processor:addProcess(createSquareProgram())

    drawRect(300, 200, 20, 20)
    createAnimatedSquare(100, 100)

    Processor:addThread(function()
        while true do
            local start = love.timer.getTime()
            -- Делаем какую-то работу
            for i = 1, 1000 do
                local x = math.random(1, 400)
                local y = math.random(1, 300)
                DRW(x, y, 255, 0, 0)
            end
            local duration = love.timer.getTime() - start
            print(string.format("Thread executed in %.4f sec at %d MHz", duration, Processor.currentClockSpeed))
            SLEEP(0.5)
        end
    end)

    MB:addInterrupt("TIMER", {interval = 1})
end

function love.update(dt)
    PSU:update(dt)
    MB:update(dt)
    RAM:update(dt)
    Cooler:update(dt)
    Processor:update(dt)
    GPU:update(dt)
    MONITOR:update(dt)
    HDD:update(dt)

    if love.keyboard.isDown("1") then
        createAnimatedSquare(math.random(0, 400), math.random(0, 300))
        drawRect(math.random(0, 400), math.random(0, 300), math.random(3, 30), math.random(3, 30))
    end

    if love.keyboard.isDown("2") then
        Processor:removeThread(1)
    end

    if love.keyboard.isDown("b") then
        Processor.autoBoost = not Processor.autoBoost
    end
end

function love.draw()
    MONITOR:draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)

    local info = Processor:getInfo()
    love.graphics.print(string.format("Frequency: %d/%d MHz (max: %d, min: %d)", 
        info.clockSpeed, info.baseClockSpeed, info.maxClockSpeed, info.minClockSpeed), 10, 130)
    love.graphics.print(string.format("Power usage: %.1f/%d W", 
        info.powerUsage, info.maxPowerUsage), 10, 150)
    love.graphics.print(string.format("TDP: %.1f/%d (%.1f%%)", 
        info.TPD, info.maxTPD, (info.TPD/info.maxTPD)*100), 10, 170)
    love.graphics.print(string.format("Processes: %d, Auto-boost: %s", 
        info.threads, info.autoBoost and "ON" or "OFF"), 10, 190)
    love.graphics.print(string.format("Thermal status: %s", 
        info.thermalThrottle and "THROTTLING" or "NORMAL"), 10, 210)

    love.graphics.print("Controls: 1 - add random process, 2 - remove process, B - toggle auto-boost", 10, 240)
    love.graphics.print("Processes change automatically every 3 seconds", 10, 260)

    love.graphics.print(string.format("Motherboard: %s (BIOS %s)", MB.model, MB.bios.version), 300, 10)
    love.graphics.print(string.format("Clock: %.1f MHz (Stability: %.0f%%)", 
        MB.clockGenerator.currentFrequency, MB.clockGenerator.stability*100), 300, 30)
    love.graphics.print(string.format("Power: %.1fV (%.1fW)",
        MB.powerDelivery.voltage, MB.powerDelivery.voltage * MB.powerDelivery.maxAmperage), 300, 50)
        local totalPeripheralPower = (Cooler:getPowerConsumption() or 0) + RAM:getPowerConsumption()
    love.graphics.print(string.format("Peripherals: %.1fW", totalPeripheralPower), 300, 250)

        local psuInfo = PSU:getInfo()
    love.graphics.print(string.format("PSU: %s (%.1f°C, Fan: %d%%)", 
        psuInfo.model, psuInfo.temperature, psuInfo.fanSpeed), 10, 380)
    love.graphics.print(string.format("+12V: %.1fA | +5V: %.1fA | +3.3V: %.1fA", 
        psuInfo.rails["+12V"], psuInfo.rails["+5V"], psuInfo.rails["+3.3V"]), 10, 400)
        love.graphics.print(string.format("RAM Power: %.1fW", RAM:getPowerConsumption()), 10, 420)

        local coolerInfo = Cooler:getInfo()
    love.graphics.print(string.format("Cooler: %s (%.1f°C)", coolerInfo.model, coolerInfo.temperature), 300, 70)
    love.graphics.print(string.format("Fan: %d/%d RPM (%.1f%%)", 
        coolerInfo.rpm, coolerInfo.maxRPM, (coolerInfo.rpm/coolerInfo.maxRPM)*100), 300, 90)
    love.graphics.print(string.format("Noise: %.1f dB, Efficiency: %.1f%%", 
        coolerInfo.noiseLevel, coolerInfo.efficiency), 300, 110)
    love.graphics.print(string.format("Cooling power: %.1f W/°C", coolerInfo.coolingPower), 300, 130)

    local ramInfo = RAM:getInfo()
    love.graphics.print(string.format("RAM: %s %dMB", ramInfo.model, ramInfo.capacity), 300, 170)
    love.graphics.print(string.format("Freq: %dMHz, Timings: %s", ramInfo.frequency, ramInfo.timings), 300, 190)
    love.graphics.print(string.format("Usage: %.1f%%, Temp: %.1f°C", ramInfo.utilization, ramInfo.temperature), 300, 210)
    love.graphics.print(string.format("Power: %.1fW, Errors: %d", ramInfo.powerUsage, ramInfo.errors), 300, 230)

    local gpuInfo = GPU:getInfo()
    love.graphics.print("GPU: "..gpuInfo.model, 300, 270)
    love.graphics.print("Clock: "..gpuInfo.clock, 300, 290)
    love.graphics.print("Temp: "..gpuInfo.temperature, 300, 310)
    love.graphics.print("Power: "..gpuInfo.power, 300, 330)
    love.graphics.print("Utilization: "..gpuInfo.utilization, 300, 350)
    love.graphics.print("FPS: "..gpuInfo.fps, 300, 370)

    local hddInfo = HDD:getInfo()
love.graphics.print(string.format("HDD: %s (%.1f°C)", hddInfo.model, hddInfo.temperature), 300, 390)
love.graphics.print(string.format("Usage: %.2fMB/%.2fGB (%.1f%%)", 
    hddInfo.usedSpace, hddInfo.capacity/1024, hddInfo.utilization), 300, 410)
love.graphics.print(string.format("Speed: R:%.1f/W:%.1f MB/s", 
    hddInfo.readSpeed, hddInfo.writeSpeed), 300, 430)
love.graphics.print(string.format("Power: %.1fW, State: %s", 
    hddInfo.powerUsage, hddInfo.isSpinning and "ACTIVE: IDLE"), 300, 450)
end
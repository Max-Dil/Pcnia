--love.window.setMode(400, 300)

local Processor = require("CPU.Zero1")
--local Processor = require("CPU.Zero2")
local Alpeg1000 = require("MOTHER.Alpeg1000")
local Enma1 = require("POWER.Enma1")
local Swipan = require("COOLER.Swipan")
local Unsa2x10m = require("RAM.Unsa 2x10m")
local Huga = require("MONITOR.Huga")
local Avrora = require("GPU.Avrora")
--local Avrora = require("GPU.Neptun")
local Typyka = require("DISK.Typyka")
local OC = require("OC.TinuOC")
local font = love.graphics.newFont(14)
_G.love = love

function love.load()
    OC:init({
        processor = Processor,
        mother = Alpeg1000,
        cooler = Swipan,
        ram = Unsa2x10m,
        gpu = Avrora,
        disk = Typyka,
        blockEnergy = Enma1,
        monitor = Huga
    })
end

function love.update(dt)
    OC:update(dt)
end

function love.mousereleased(x, y, button, isTouch)
    if OC.mousereleased then
        OC.mousereleased(x, y, button, isTouch)
    end
end

function love.mousepressed(x, y, button, isTouch)
    if OC.mousepressed then
        OC.mousepressed(x, y, button, isTouch)
    end
end

function love.mousemoved(x, y, dx, dy)
    if OC.mousemoved then
        OC.mousemoved(x, y, dx, dy)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if OC.keypressed then
        OC.keypressed(key, scancode, isrepeat)
    end
end

function love.draw()
    OC:draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.scale(0.8, 0.8)
    love.graphics.translate(300, 200)

    love.graphics.print(love.timer.getFPS(), 0, 0)

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
    love.graphics.print(string.format("Load: %s%%", 
        info.cpuLoad), 10, 225)
    info = nil

    love.graphics.print(string.format("Motherboard: %s (BIOS %s)", MB.model, MB.bios.version), 300, 10)
    love.graphics.print(string.format("Clock: %.1f MHz (Stability: %.0f%%)", 
        MB.clockGenerator.currentFrequency, MB.clockGenerator.stability*100), 300, 30)
    love.graphics.print(string.format("Power: %.1fV (%.1fW)",
        MB.powerDelivery.voltage, MB.powerDelivery.voltage * MB.powerDelivery.maxAmperage), 300, 50)
        local totalPeripheralPower = (COOLER:getPowerConsumption() or 0) + RAM:getPowerConsumption()
    love.graphics.print(string.format("Peripherals: %.1fW", totalPeripheralPower), 300, 250)

        local psuInfo = PSU:getInfo()
    love.graphics.print(string.format("PSU: %s (%.1f°C, Fan: %d%%)", 
        psuInfo.model, psuInfo.temperature, psuInfo.fanSpeed), 10, 380)
    love.graphics.print(string.format("+12V: %.1fA | +5V: %.1fA | +3.3V: %.1fA", 
        psuInfo.rails["+12V"], psuInfo.rails["+5V"], psuInfo.rails["+3.3V"]), 10, 400)
        love.graphics.print(string.format("RAM Power: %.1fW", RAM:getPowerConsumption()), 10, 420)
        psuInfo = nil

        local coolerInfo = COOLER:getInfo()
    love.graphics.print(string.format("Cooler: %s (%.1f°C)", coolerInfo.model, coolerInfo.temperature), 300, 70)
    love.graphics.print(string.format("Fan: %d/%d RPM (%.1f%%)", 
        coolerInfo.rpm, coolerInfo.maxRPM, (coolerInfo.rpm/coolerInfo.maxRPM)*100), 300, 90)
    love.graphics.print(string.format("Noise: %.1f dB, Efficiency: %.1f%%", 
        coolerInfo.noiseLevel, coolerInfo.efficiency), 300, 110)
    love.graphics.print(string.format("Cooling power: %.1f W/°C", coolerInfo.coolingPower), 300, 130)
    coolerInfo = nil

    local ramInfo = RAM:getInfo()
    love.graphics.print(string.format("RAM: %s %dMB", ramInfo.model, ramInfo.capacity/1024/1024), 300, 170)
    love.graphics.print(string.format("Freq: %dMHz, Timings: %s", ramInfo.frequency, ramInfo.timings), 300, 190)
    love.graphics.print(string.format("Usage: %.1f%%, Temp: %.1f°C, RAM: %d", -ramInfo.utilization, ramInfo.temperature, ramInfo.freeMemory / 1024), 300, 210)
    love.graphics.print(string.format("Power: %.1fW, Errors: %d", ramInfo.powerUsage, ramInfo.errors), 300, 230)
    ramInfo = nil

    local gpuInfo = GPU:getInfo()
    love.graphics.print("GPU: "..gpuInfo.model, 300, 270)
    love.graphics.print("Clock: "..gpuInfo.clock, 300, 290)
    love.graphics.print("Temp: "..gpuInfo.temperature, 300, 310)
    love.graphics.print("Power: "..gpuInfo.power, 300, 330)
    love.graphics.print("Utilization: "..gpuInfo.utilization, 300, 350)
    love.graphics.print("FPS: "..gpuInfo.fps, 300, 370)
    gpuInfo = nil

    local hddInfo = HDD:getInfo()
love.graphics.print(string.format("HDD: %s (%.1f°C)", hddInfo.model, hddInfo.temperature), 300, 390)
love.graphics.print(string.format("Usage: %.2fMB/%.2fGB", 
    hddInfo.usedSpace/1024, hddInfo.capacity/1024), 300, 410)
love.graphics.print(string.format("Speed: R:%.1f/W:%.1f MB/s", 
    hddInfo.readSpeed, hddInfo.writeSpeed), 300, 430)
love.graphics.print(string.format("Power: %.1fW, State: %s", 
    hddInfo.powerUsage, hddInfo.isSpinning and "ACTIVE: IDLE"), 300, 450)
    hddInfo = nil
    return
end







-- local data = {}
-- for image_x = 1, 32 do
--     data[image_x] = {}
--     for image_y = 1, 32 do
--         -- Определяем цвет пикселя (RGB)
--         if image_y <= 4 then
--             data[image_x][image_y] = {0, 0, 255}
--         elseif image_y == 5 then
--             data[image_x][image_y] = {0, 0, 0}
--         elseif image_y > 5 and image_y <= 32 then
--             if image_x % 4 == 0 or image_y % 4 == 0 then
--                 data[image_x][image_y] = {200, 200, 200}
--             else
--                 data[image_x][image_y] = {255, 255, 255}
--             end
--         end
--     end
-- end

-- print(require("json").encode(data))
_G.love = love
_G.json = require("json")

local CPU = require("CPU.Zero5000 PRO MAX")
local GPU = require("GPU.Avrora")
local MOTHER = require("MOTHER.Alpeg1000")
local BLOCK = require("POWER.Enma1")
local COOLER = require("COOLER.Swipan")
local MONITOR = require("MONITOR.Huga")
local RAM = require("RAM.Unsa 2x10m")
local DISK = require("DISK.Typyka")

local OC = require("OC.Tinu.core.Tinu")

-- love.window.setMode(1200, 900, {vsync = 0})
function love.load()
    OC.init({
        cpu = CPU,
        gpu = GPU,
        mother = MOTHER,
        monitor = MONITOR,
        cooler = COOLER,
        ram = RAM,
        disk = DISK,
        block = BLOCK
    })
end

function love.update(dt)
    OC.update(dt)
end

function love.keyreleased(key)
    if OC.keyreleased  then
        OC.keyreleased(key)
    end
end

function love.keypressed(key)
    if OC.keypressed then
        OC.keypressed(key)
    end
end

function love.draw()
    OC.draw()

    -- love.graphics.scale(0.8, 0.8)
    love.graphics.print(love.timer.getFPS(), 0, 0)
    -- love.graphics.print("Memory usage: " .. collectgarbage("count") .. " KB", 10, 10)

    local info = CPU:getInfo()
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

    love.graphics.print(string.format("Motherboard: %s (BIOS %s)", MOTHER.model, MOTHER.bios.version), 300, 10)
    love.graphics.print(string.format("Clock: %.1f MHz (Stability: %.0f%%)", 
        MOTHER.clockGenerator.currentFrequency, MOTHER.clockGenerator.stability*100), 300, 30)
    love.graphics.print(string.format("Power: %.1fV (%.1fW)",
        MOTHER.powerDelivery.voltage, MOTHER.powerDelivery.voltage * MOTHER.powerDelivery.maxAmperage), 300, 50)
        local totalPeripheralPower = (COOLER:getPowerConsumption() or 0) + RAM:getPowerConsumption()
    love.graphics.print(string.format("Peripherals: %.1fW", totalPeripheralPower), 300, 250)

        local psuInfo = BLOCK:getInfo()
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
    love.graphics.print(string.format("RAM: %s %dMOTHER", ramInfo.model, ramInfo.capacity/1024/1024), 300, 170)
    love.graphics.print(string.format("Freq: %dMHz, Timings: %s", ramInfo.frequency, ramInfo.timings), 300, 190)
    love.graphics.print(string.format("Usage: %.1f%%, Temp: %.1f°C, RAM: %d/%d", ramInfo.utilization, ramInfo.temperature, ramInfo.freeMemory / 1024, RAM.capacity/1024), 300, 210)
    love.graphics.print(string.format("Power: %.1fW, Errors: %d", ramInfo.powerUsage, ramInfo.errors), 300, 230)
    ramInfo = nil

    local gpuInfo = GPU:getInfo()
    love.graphics.print("GPU: "..gpuInfo.model, 300, 270)
    love.graphics.print("Clock: "..json.encode(gpuInfo.clock), 300, 290)
    love.graphics.print("Temp: "..json.encode(gpuInfo.temperature), 300, 310)
    love.graphics.print("Power: "..json.encode(gpuInfo.power), 300, 330)
    love.graphics.print("Utilization: "..json.encode(gpuInfo.utilization), 300, 350)
    love.graphics.print("FPS: "..gpuInfo.fps, 300, 370)
    gpuInfo = nil

    local hddInfo = DISK:getInfo()
love.graphics.print(string.format("HDD: %s (%.1f°C)", hddInfo.model, hddInfo.temperature), 300, 390)
love.graphics.print(string.format("Usage: %.2fMOTHER/%.2fGB", 
    hddInfo.usedSpace/1024, hddInfo.capacity/1024), 300, 410)
love.graphics.print(string.format("Speed: R:%.1f/W:%.1f MOTHER/s", 
    hddInfo.readSpeed, hddInfo.writeSpeed), 300, 430)
love.graphics.print(string.format("Power: %.1fW, State: %s", 
    hddInfo.powerUsage, hddInfo.isSpinning and "ACTIVE: IDLE"), 300, 450)
    hddInfo = nil
end
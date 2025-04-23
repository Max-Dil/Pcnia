-- Блок питания Enma1
local Enma1 = {
    model = "Enma1",
    version = "2.4",

    maxPower = 100,          -- Максимальная мощность (Вт)
    efficiency = 0.8,       -- КПД (80 BRonza)
    voltageRails = {
        ["+12V"] = { maxCurrent = 30, current = 0, voltage = 12 },
        ["+5V"]  = { maxCurrent = 15, current = 0, voltage = 5 },
        ["+3.3V"] = { maxCurrent = 10, current = 0, voltage = 3.3 }
    },

    temperature = 30,        -- Стартовая температура (°C)
    minTemperature = 25,     -- Минимальная возможная температура
    fanSpeed = 5,           -- Скорость вентилятора (%)
    overloadProtection = true,

    motherboard = nil,

    powerDrawHistory = {},
    maxHistorySize = 60
}

function Enma1:init(motherboard)
    self.motherboard = motherboard
    print(string.format("[%s] Initialized, connected to %s", self.model, motherboard.model))
    return self
end

function Enma1:calculateAvailablePower()
    local usedPower = 0
    for _, rail in pairs(self.voltageRails) do
        usedPower = usedPower + (rail.voltage * rail.current)
    end
    return self.maxPower - usedPower
end

function Enma1:deliverPower(rail, requiredWatts)
    if not self.voltageRails[rail] then
        error(string.format("Rail %s does not exist", rail))
    end

    local railInfo = self.voltageRails[rail]
    local requiredCurrent = requiredWatts / railInfo.voltage
    
    if requiredCurrent > railInfo.maxCurrent then
        if self.overloadProtection then
            print(string.format("[%s] WARNING: Overload on %s rail! Requested %.1fA, max %.1fA", 
                self.model, rail, requiredCurrent, railInfo.maxCurrent))
            requiredCurrent = railInfo.maxCurrent * 0.8
            requiredWatts = requiredCurrent * railInfo.voltage
        else
            print(string.format("[%s] CRITICAL: Overload on %s rail!", self.model, rail))
        end
    end

    railInfo.current = requiredCurrent
    
    local actualPower = requiredWatts * self.efficiency

    self.temperature = math.max(
        self.minTemperature,
        self.temperature + (actualPower * 0.1 - self.fanSpeed * 0.05)
    )
    
    self:updateCooling()

    table.insert(self.powerDrawHistory, actualPower)
    if #self.powerDrawHistory > self.maxHistorySize then
        table.remove(self.powerDrawHistory, 1)
    end
    
    return actualPower
end

function Enma1:updateCooling()
    if self.temperature > 50 then
        self.fanSpeed = math.min(100, self.fanSpeed + 2)
    elseif self.temperature < 40 then
        self.fanSpeed = math.max(10, self.fanSpeed - 1)
    end
    
    self.temperature = math.max(self.minTemperature, self.temperature)
end

function Enma1:update(dt)
    local cpuPowerNeeded = math.min(self.motherboard.cpu.powerUsage, self.motherboard.cpu.maxPowerUsage)

    local coolerPower = 0
    if self.motherboard.cooler then
        coolerPower = self.motherboard.cooler:getPowerConsumption()
    end

    local ramPower = 0
    if self.motherboard.memoryController and #self.motherboard.memoryController.memoryModules > 0 then
        ramPower = self.motherboard.memoryController.memoryModules[1]:getPowerConsumption()
    end

    local gpuPower = 0
    if self.motherboard.gpu then
        gpuPower = self.motherboard.gpu:getPowerConsumption()
    end

    local monitorPower = 0
    if self.monitor then
        monitorPower = self.motherboard.monitor:getPowerConsumption()
    end

    local hddPower = 0
    for i = 1, #self.motherboard.storages, 1 do
        hddPower = hddPower + self.motherboard.storages[i]:getPowerConsumption()
    end
    local hdd12v = hddPower * 0.7
    local hdd5v = hddPower * 0.3

    local cpuPower = self:deliverPower("+12V", cpuPowerNeeded + gpuPower + hdd12v)
    local coolerPowerActual = self:deliverPower("+5V", coolerPower + monitorPower + hdd5v)
    local ramPowerActual = self:deliverPower("+3.3V", ramPower)

    self.motherboard.powerDelivery.voltage = 12
    self.motherboard.powerDelivery.maxAmperage = cpuPower / 12

    if self.temperature > 80 then
        print(string.format("[%s] CRITICAL TEMPERATURE: %.1f°C", self.model, self.temperature))
        self.motherboard.cpu.currentClockSpeed = math.max(
            self.motherboard.cpu.minClockSpeed,
            self.motherboard.cpu.currentClockSpeed * 0.9
        )
    end
end

function Enma1:getInfo()
    return {
        model = self.model,
        temperature = self.temperature,
        fanSpeed = self.fanSpeed,
        efficiency = self.efficiency * 100,
        availablePower = self:calculateAvailablePower(),
        rails = {
            ["+12V"] = self.voltageRails["+12V"].current,
            ["+5V"] = self.voltageRails["+5V"].current,
            ["+3.3V"] = self.voltageRails["+3.3V"].current
        }
    }
end

return Enma1
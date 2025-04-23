-- COOLER/Swipan.lua
local Swipan = {
    model = "Swipan-X1",
    version = "1.2",
    
    coolingPower = 45,        -- Максимальная мощность охлаждения (Вт/°C)
    baseNoiseLevel = 25,      -- Уровень шума в дБ на минимальных оборотах
    maxNoiseLevel = 45,       -- Уровень шума в дБ на максимальных оборотах
    minRPM = 800,            -- Минимальные обороты вентилятора
    maxRPM = 3000,           -- Максимальные обороты вентилятора

    currentRPM = 800,
    targetRPM = 800,
    efficiency = 2.0,        -- Эффективность охлаждения (может снижаться со временем)
    isActive = true,

    powerConsumption = {
        base = 5,    -- Базовое потребление (Вт) при минимальных оборотах
        max = 15     -- Максимальное потребление (Вт) при полной скорости
    },

    temperature = 30,        -- Текущая температура кулера
    ambientTemperature = 25, -- Температура окружающей среды

    processor = nil,
    motherboard = nil
}

function Swipan:init(processor, motherboard)
    self.processor = processor
    self.motherboard = motherboard
    print(string.format("[%s] Initialized, connected to %s on %s", 
        self.model, processor.model, motherboard.model))
    return self
end

function Swipan:calculateCoolingEfficiency()
    local rpmRatio = (self.currentRPM - self.minRPM) / (self.maxRPM - self.minRPM)
    return self.coolingPower * self.efficiency * rpmRatio
end

function Swipan:updateFanSpeed()
    if not self.isActive then 
        self.targetRPM = self.minRPM
        return
    end
    
    local cpuTemp = self.processor.TPD / self.processor.maxTPD * 100
    local targetTemp = 70
    
    if cpuTemp > targetTemp + 10 then
        self.targetRPM = self.maxRPM
    elseif cpuTemp > targetTemp then
        self.targetRPM = self.minRPM + (cpuTemp - targetTemp) / 10 * (self.maxRPM - self.minRPM)
    else
        self.targetRPM = self.minRPM
    end
 
    if self.currentRPM < self.targetRPM then
        self.currentRPM = math.min(self.targetRPM, self.currentRPM + 200)
    elseif self.currentRPM > self.targetRPM then
        self.currentRPM = math.max(self.targetRPM, self.currentRPM - 100)
    end
end

function Swipan:applyCooling(dt)
    if not self.isActive then return end
    
    local coolingEffect = self:calculateCoolingEfficiency() * dt

    self.processor.TPD = math.max(0, self.processor.TPD - coolingEffect)

    self.temperature = self.ambientTemperature + 
        (self.currentRPM / self.maxRPM * 15) + 
        (self.processor.TPD / self.processor.maxTPD * 10)

    if self.temperature > 60 then
        self.efficiency = math.max(0.7, 1.0 - (self.temperature - 60) * 0.01)
    else
        self.efficiency = math.min(1.0, self.efficiency + 0.01)
    end
end

function Swipan:toggle()
    self.isActive = not self.isActive
    print(string.format("[%s] Cooler %s", self.model, self.isActive and "activated" or "deactivated"))
end

function Swipan:setManualRPM(rpm)
    rpm = math.min(self.maxRPM, math.max(self.minRPM, rpm))
    self.targetRPM = rpm
    print(string.format("[%s] Manual RPM set to %d", self.model, rpm))
end

function Swipan:getPowerConsumption()
    local rpmRatio = (self.currentRPM - self.minRPM) / (self.maxRPM - self.minRPM)
    return self.powerConsumption.base + rpmRatio * (self.powerConsumption.max - self.powerConsumption.base)
end

function Swipan:update(dt)
    self:updateFanSpeed()
    self:applyCooling(dt)
end

function Swipan:getInfo()
    return {
        model = self.model,
        rpm = self.currentRPM,
        targetRPM = self.targetRPM,
        efficiency = self.efficiency * 100,
        temperature = self.temperature,
        maxRPM = self.maxRPM,
        noiseLevel = self.baseNoiseLevel + 
                     (self.currentRPM - self.minRPM) / (self.maxRPM - self.minRPM) * 
                     (self.maxNoiseLevel - self.baseNoiseLevel),
        isActive = self.isActive,
        coolingPower = self:calculateCoolingEfficiency()
    }
end

return Swipan
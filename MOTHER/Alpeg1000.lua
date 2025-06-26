-- Материнская плата Alpeg1000
local Alpeg1000 = {
    model = "Alpeg1000",
    version = "1.0",
    
    clockGenerator = {
        baseFrequency = 100,  -- Базовая частота в MHz
        currentFrequency = 100,
        stability = 1.0,       -- Стабильность генерации (0.0-1.0)
    },
    
    powerDelivery = {
        voltage = 12,            -- Вольтаж линии +12V (стандарт для CPU)
        maxAmperage = 16.67,     -- 200W / 12V = ~16.67A
        efficiency = 0.95,       -- КПД VRM (95%)
    },
    
    chipset = {
        interrupts = {},       -- Очередь прерываний
        memoryController = {
            latency = 10,      -- Задержка доступа к памяти
            bandwidth = 4096,  -- Пропускная способность (MB/s)
        }
    },
    
    bios = {
        version = "P1.20",
        settings = {
            cpuBoost = true,
            powerLimit = 100,
        }
    },

    cpu = nil,

    memoryController = {
        memoryModules = {},
        channelCount = 2,
        
        registerMemory = function(self, memoryModule)
            table.insert(self.memoryModules, memoryModule)
            print(string.format("[%s] Memory module %s registered", 
                self.model, memoryModule.model))
        end,
        
        read = function(self, address, size)
            if #self.memoryModules > 0 then
                return self.memoryModules[1]:read(address, size)
            end
            return 0
        end,
        
        write = function(self, address, ...)
            if #self.memoryModules > 0 then
                self.memoryModules[1]:write(address, ...)
            end
        end,

        free = function(self, address, count)
            if #self.memoryModules > 0 then
                self.memoryModules[1]:free(address, count)
            end
        end
    },

    storages = {}
}

function Alpeg1000:readMemory(address)
    return self.memoryController:read(address)
end

function Alpeg1000:writeMemory(address, value)
    self.memoryController:write(address, value)
end

function Alpeg1000:freeMemory(address, count)
    return self.memoryController:free(address, count)
end

function Alpeg1000:init(cpu)
    self.cpu = cpu
    self.cooler = nil
    print(string.format("[Alpeg1000] Initialized with CPU %s", cpu.model or "unknown"))
    return self
end

function Alpeg1000:attachCooler(cooler)
    self.cooler = cooler
    print(string.format("[Alpeg1000] Cooler %s attached", cooler.model))
end

function Alpeg1000:attachStorage(storage)
    table.insert(self.storages, storage)
    print(string.format("[%s] Storage %s attached", self.model, storage.model))
end

function Alpeg1000:deliverPower()
    local maxCpuPower = self.powerDelivery.voltage * self.powerDelivery.maxAmperage
    local actualPower = math.min(self.cpu.powerUsage, maxCpuPower)
    
    local peripheralPower = 0

    if self.cooler then
        peripheralPower = peripheralPower + self.cooler:getPowerConsumption()
    end

    if self.gpu then
        peripheralPower = peripheralPower + self.gpu:getPowerConsumption()
    end

    if self.monitor then
        peripheralPower = peripheralPower + self.monitor:getPowerConsumption()
    end

    for i = 1, #self.storages, 1 do
        peripheralPower = peripheralPower + self.storages[i]:getPowerConsumption()
    end

    if self.memoryController and #self.memoryController.memoryModules > 0 then
        for _, ram in ipairs(self.memoryController.memoryModules) do
            peripheralPower = peripheralPower + ram:getPowerConsumption()
        end
    end

    actualPower = math.max(0, actualPower - peripheralPower)

    return actualPower * self.powerDelivery.efficiency
end

function Alpeg1000:handleInterrupts()
    if #self.chipset.interrupts > 0 then
        local interrupt = table.remove(self.chipset.interrupts, 1)
        print(string.format("[Alpeg1000] Handling interrupt: %s", interrupt.type))
    end
end

function Alpeg1000:applyBiosSettings()
    if self.bios.settings.cpuBoost ~= self.cpu.autoBoost then
        self.cpu.autoBoost = self.bios.settings.cpuBoost
        print("[Alpeg1000] Updated CPU boost setting")
    end
end

function Alpeg1000:update(dt)

    
    local power = self:deliverPower()
    if power > self.powerDelivery.maxAmperage * self.powerDelivery.voltage then
        print("[Alpeg1000] WARNING: Power limit exceeded!", power, self.powerDelivery.maxAmperage * self.powerDelivery.voltage)
    end
    
    self:applyBiosSettings()
    
    self:handleInterrupts()
end

function Alpeg1000:addInterrupt(intType, data)
    table.insert(self.chipset.interrupts, {
        type = intType,
        data = data,
        time = os.time()
    })
end

return Alpeg1000
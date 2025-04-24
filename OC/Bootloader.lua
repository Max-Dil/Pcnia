local json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinyOS"
}

--[[
0x000000 - 0x000FFF   | Загрузочный сектор (MBR)
0x001000 - 0x00FFFF   | Ядро ОС (до 60KB)
0x010000 - 0x0FFFFF   | Файловая система (до 15MB)
0x100000 - ...        | Пользовательские данные
]]

function OC:init(data)
    CPU = data.processor
    data.processor:init()
    MB = data.mother:init(data.processor)
    data.processor.motherboard = MB
    RAM = data.ram:init(MB)
    Cooler = data.cooler:init(data.processor, MB)
    MB:attachCooler(Cooler)
    PSU = data.blockEnergy:init(MB)
    GPU = data.gpu:init(data.processor)
    MONITOR = data.monitor:init(GPU)
    data.processor:setGPU(GPU)
    MB.gpu = GPU
    MB.monitor = MONITOR
    HDD = data.disk:init(MB)
    MB:attachStorage(HDD)
    MB:addInterrupt("TIMER", {interval = 1})

    HDD:addEventListener("write", function(hdd, address, size)
        print(string.format("[HDD] Write: addr=%d, size=%d, used=%.2fMB/%.2fMB", 
            address, size, hdd.usedSpace, hdd.effectiveCapacity))
    end)

    HDD:addEventListener("read", function(hdd, address, size)
        print(string.format("[HDD] Read: addr=%d, size=%d", address, size))
    end)
    
    HDD:loadFromFile()
    HDD:read(0, 512, function (mbr, bytesRead, err)
        if err then
            local bootloader = string.rep("\0", 510)
            bootloader = bootloader .. "\x55\xAA"
            HDD:write(0, bootloader, function(success)
                if success then
                    HDD:saveToFile()
                    OC:loadOS()
                end
            end)
        else
            OC:loadOS()
        end
    end)
end

function OC:loadOS()
    HDD:read(0x1000, 1024, function(kernelData, bytesRead, err)
        self:startOS()
    end)
end

function OC:installDefaultOS()
    print("[OS] Installing default OS...")

    local kernel = {
        version = self.version,
        name = self.name,
        init = string.dump(function ()
            print(900)
        end)
    }

    local kernelData = json.encode(kernel)
    HDD:write(0x1000, kernelData, function(success)
        if success then
            HDD:saveToFile()
            print("[OS] Default OS installed successfully")
            self:startOS()
        else
            print("[OS] Error installing default OS")
        end
    end)
end

function OC:startOS()
    HDD:read(0x1000, 1024, function(kernelData, bytesRead, err)
        kernelData = string.gsub(kernelData, "\0", "")
        local kernel = json.decode(kernelData)
        if kernel and kernel.init then
            local init = loadstring(kernel.init)
            init()
        else
            print("[OS] Error: Invalid kernel data")
            self:installDefaultOS()
        end
    end)
end

function OC:update(dt)
    PSU:update(dt)
    MB:update(dt)
    RAM:update(dt)
    Cooler:update(dt)
    CPU:update(dt)
    GPU:update(dt)
    MONITOR:update(dt)
    HDD:update(dt)
end

return OC
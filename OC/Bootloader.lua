local json = require("json")

OC = {
    path = ...,
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
        if err  then
            local bootloader = string.rep("\0", 510)
            bootloader = bootloader .. "\x55\xAA"
            HDD:write(0, bootloader, function(succes)
                if succes then
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
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
    HDD:read(0, 512, function (mbr)
        if not mbr or #mbr < 512 then
            print("[BOOT] No OS found, formatting disk...")
            HDD:formatFS()

            local bootloader = string.rep("\0", 510)
            bootloader = bootloader .. "\x55\xAA"
            HDD:write(0, bootloader, function ()
                OC:loadOS()
            end)
        end
    end)

    OC:loadOS()
end

function OC:loadOS()
    local mbr = HDD:read(0, 512)
    
    if not mbr or #mbr < 512 then
        print("[BOOT] Error: Invalid or corrupted MBR")
        return false
    end

    local signature = string.byte(mbr, 511) + string.byte(mbr, 512) * 256
    if signature ~= 0xAA55 then
        print("[BOOT] Error: Invalid boot signature")
        return false
    end

    local kernelSize = 60 * 1024 
    local kernel = HDD:read(0x1000, kernelSize)
    
    if not kernel then
        print("[BOOT] Error: Failed to load kernel")
        return false
    end
    
    print(string.format("[BOOT] Kernel loaded (%d bytes)", #kernel))

    self:initFS()

    return self:startKernel(kernel)
end

function OC:initFS()
    local superblock = HDD:read(0x10000, 1024)
    
    -- Простая файловая система:
    -- 1. Первые 1024 байт - суперблок
    -- 2. Далее таблица inode (1024 записей по 64 байта = 64KB)
    -- 3. Битовая карта блоков (16KB)
    -- 4. Данные файлов
    
    self.fs = {
        superblock = superblock,
        inodeTable = {},
        blockMap = {}
    }
    
    print("[FS] Simple filesystem initialized")
end

function OC:startKernel(kernel)

    print("[OS] Starting kernel...")

    MONITOR:displayText(10, 10, "OS Kernel v1.0", 0xFFFFFF)
    MONITOR:displayText(10, 30, "Initializing hardware...", 0xFFFFFF)

    for i = 1, 5 do
        MONITOR:displayText(10, 50 + i*20, string.format("Loading module %d...", i), 0xFFFFFF)
        love.timer.sleep(0.5)
    end

    MONITOR:displayText(10, 170, "System ready!", 0x00FF00)

    return true
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
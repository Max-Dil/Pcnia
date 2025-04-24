local json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinyOS"
}

--[[
is_load   | Загрузочный сектор (MBR)
core  | Ядро ОС (до 60KB)
files   | Файловая система (до 15MB)
users - ...        | Пользовательские данные
]]

function OC:init(data)
    CPU = data.processor
    data.processor:init()
    MB = data.mother:init(data.processor)
    CPU:setMotherboard(MB)
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

    CPU:addThread(function ()
        LDA({255, 255, 255})

        LDX("Load TinyOC")
        DTX(10, 10, X(), A(), 2)

        LDX("by Stimor")
        DTX(MONITOR.resolution.width - 70 , MONITOR.resolution.height - 10, X(), A(), 1)

        LDX("Tiny OC corparation")
        LDA({255, 0, 255})
        DTX(MONITOR.resolution.width/2 - (6 * #X()), MONITOR.resolution.height/2 - 10, X(), A(), 2)
    end)
    
    --HDD:loadFromFile()
    HDD:read("is_load", function (is_load)
        if is_load ~= "true" then
            HDD:write("is_load", "true", function(success)
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
    HDD:read("core", function()
        self:startOS()
    end)
end

function OC:installDefaultOS()
    print("[OS] Installing default OS...")

    local kernel = {
        version = self.version,
        name = self.name,
    }

    local kernelData = json.encode(kernel)
    HDD:write("core", kernelData, function(success)
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
    local init = function ()
        CPU:addThread(function ()
            GPU:clear()

            LDA({255, 255, 255})
            LDX("TinyOS")
            DTX(10, 10, X(), A(), 2)
        end)
    end

    HDD:read("core", function(kernelData)
        if kernelData == '' then
            print("[OS] Error: Invalid kernel data")
            self:installDefaultOS()
            return
        end
        local kernel = json.decode(kernelData)
        if kernel then
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

function OC:draw()
    MONITOR:draw()
end

return OC
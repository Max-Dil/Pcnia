local json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinyOS",
}

--[[
is_load   | Загрузочный сектор (MBR)
core  | Ядро ОС
files   | Файловая система
users - ...        | Пользовательские данные
apps | приложения
]]

--[[
Архитектура приложения:
name | имя программы
version | версия
company | компания
autoLoad | автозагрузка
scripts {} | скрипты
main | оснвоной скрипт
]]

--[[
0 | запущенные приложений
1 | интерфейс ос 
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
    data.gpu.driver = "Unakoda"
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

    HDD:addEventListener("write", function(hdd, address)
        print(string.format("[HDD] Write: addr=" .. address .. ", used=%.2fMB/%.2fMB",
            hdd.usedSpace/1024, hdd.effectiveCapacity))
    end)

    HDD:addEventListener("read", function(hdd, address)
        print(string.format("[HDD] Read: addr=" .. address))
    end)

    HDD:loadFromFile()
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

-- Приложения --------------------
function OC:installApp(appData, callback)
    if type(appData) ~= "table" or not appData.name or not appData.main or not appData.scripts then
        print("[OS] Error: Invalid app data structure")
        return false
    end

    local appIndex = "app_" .. appData.name:lower():gsub("[^%w]", "_")

    print("apps/" .. appIndex)
    HDD:write("apps/" .. appIndex, json.encode(appData), function(success)
        if success then
            print("[OS] App '" .. appData.name .. "' installed successfully")
            if appData.autoLoad then
                self:addToAutoload(appIndex)
            end
            HDD:saveToFile()
            callback(true)
        else
            print("[OS] Error: Failed to install app '" .. appData.name .. "'")
        end
    end)
    
    return true
end

function OC:addToAutoload(appIndex)
    HDD:read("core", function(kernelData)
        local kernel = json.decode(kernelData) or {}
        kernel.auto_load_apps = kernel.auto_load_apps or {}

        for _, v in ipairs(kernel.auto_load_apps) do
            if v == appIndex then return end
        end

        table.insert(kernel.auto_load_apps, appIndex)
        HDD:write("core", json.encode(kernel))
    end)
end

function OC:loadApp(appIndex)
    local apps = RAM:read(0)
    local app = apps[appIndex]
    if app then
        self:runApp(app, appIndex)
        return
    end

    HDD:read("apps/" .. appIndex, function(appJson)
        if not appJson or appJson == "" then
            print("[OS] Error: App not found - " .. appIndex)
            return
        end
        
        local app = json.decode(appJson)
        if not app then
            print("[OS] Error: Invalid app data for " .. appIndex)
            return
        end

        apps[appIndex] = app
        RAM:write(0, apps)
        self:runApp(app)
    end)
end

function OC:runApp(app, appIndex)
    if not app.name or not app.main or not app.scripts then
        print("[OS] Error: App is missing required fields")
        return
    end

    if not app.scripts[app.main] then
        print("[OS] Error: App is missing launch main script")
        return
    end

    local script = string.format([[
        return function()
            GPU:clear()
            LDA("]] .. app.name .. [[")
            DTX(MONITOR.resolution.width/2 - (#A() * 6), 10, A(), {255, 255, 255}, 2)
            for x=1, 10 do
                for y=1, 10 do
                    DRW(MONITOR.resolution.width - 20 + x, 20 - y, 255, 0, 0)
                end
            end
            %s
        end
    ]], app.scripts[app.main])

    local main, err = loadstring(script)
    if err then
        print("[OS] Error: App - "..err)
        return
    end

    CPU:addThread(main())

    print("[OS] Succes launch App: " .. app.name)
end
----------------------------------

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
        auto_load_apps = {},
    }

    HDD:write("apps", "{}", function (success)
        if success then
            local kernelData = json.encode(kernel)
            HDD:write("core", kernelData, function(success)
                if success then
                    OC:installApp({
                        name = "MyApp",
                        version = "1.0",
                        main = "main",
                        autoLoad = true,
                        scripts = {
                            main = [[
                                for i=1, 200 do
                                    for i2=1, 200 do
                                        DRW(i, i2, 255, 255, 255)
                                    end
                                end
                            ]]
                        }
                    }, function ()
                        print("[OS] Default OS installed successfully")
                        HDD:saveToFile()
                        self:startOS()
                    end)
                else
                    print("[OS] Error installing default OS")
                end
            end)
        else
            print("[OS] Error installing default OS")
        end
    end)
end

function OC:startOS()
    local init = function (kernel)
        CPU:addThread(function ()
            write(0, {}) -- apps
            write(1, function ()
                GPU:clear()

                LDA({255, 255, 255})
                LDX(kernel.name .. " v" .. kernel.version)
                DTX(10, 10, X(), A(), 2)

                --DRE(0, 0, 400, 300, {255, 255, 255})
            end)
            read(1)()
            -- for i = 1, #kernel.auto_load_apps, 1 do
            --     OC:loadApp(kernel.auto_load_apps[i])
            -- end
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
            init(kernel)
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
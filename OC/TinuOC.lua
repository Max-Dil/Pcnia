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
2 | окружения запущенный приложений
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

    --HDD:loadFromFile()
    HDD:read("is_load", function (is_load)
        if is_load ~= "true" then
            HDD:write("is_load", "true", function(success)
                if success then
                    HDD:saveToFile()
                    self:startOS()
                end
            end)
        else
            self:startOS()
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

function OC:runAppScript(scriptName, app)
    if not app.scripts or not app.scripts[scriptName] then
        print("[OS] Error: Script '" .. scriptName .. "' not found")
        return false
    end

    local script = [=[
        local APP = RAM:read(2)["]=] .. app.name .. ":" .. app.version .. [=["]
        local read = APP.env.read
        local write = APP.env.write
        local json = APP.env.json
        local addEvent = APP.env.addEvent
        local runScript = APP.env.runScript

        local __DRW = DRW
        local DRW = function(...)
            if APP.isVisible then
                __DRW(...)
            end
        end

        local __DTX = DTX
        local DTX = function(...)
            if APP.isVisible then
                __DTX(...)
            end
        end

        local __DRE = DRE
        local DRE = function(...)
            if APP.isVisible then
                __DRE(...)
            end
        end
    ]=]..
    app.scripts[scriptName]
    local chunk, err = loadstring(script)
    if not chunk then
        print("[OS] Error compiling script '" .. scriptName .. "': " .. err)
        return false
    end

    local success, co = CPU:addThread(chunk)

    if success and co then
        local APP = RAM:read(2)[app.name .. ":" .. app.version]
        table.insert(APP.threads, co)
        return true
    else
        print("[OS] Error running script '" .. scriptName .. "': " .. tostring(co))
        return false
    end
end

function OC:runApp(app, appIndex)
    local APP
    if not app.name or not app.main or not app.scripts then
        print("[OS] Error: App is missing required fields")
        return
    end

    if not app.scripts[app.main] then
        print("[OS] Error: App is missing launch main script")
        return
    end

    local ram_x, ram_y = 50, 100

    local searchRam
    searchRam = function(x, y)
        local is_search = false
        for i = ram_x, ram_y do
            if RAM:read(i) ~= 0 then
                is_search = true
            end
        end
        if is_search then
            ram_x, ram_y = ram_x + 50, ram_y + 50
            searchRam(ram_x, ram_y)
        end
    end
    searchRam(ram_x, ram_y)

    local function restrictedRead(address)
        if ram_x + address > ram_y then
            return "Limit App Ram (50)"
        end
        return RAM:read(ram_x + address)
    end

    local function restrictedWrite(address, data)
        if ram_x + address > ram_y then
            return "Limit App Ram (50)"
        end
        RAM:write(ram_x + address, data)
    end

    local __events = {
        mousereleased = {}
    }

    local function handleMouseReleased(x, y)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        if x > MONITOR.resolution.width - 20 and x < MONITOR.resolution.width - 10 and y < 30 and y > 10 then
            APP.close(ram_x, ram_y)
        end
        if x > MONITOR.resolution.width - 35 and x < MONITOR.resolution.width - 25 and y < 20 and y > 10 then
            APP.hide()
        end
        for i = 1, #__events.mousereleased do
            __events.mousereleased[i](x, y)
        end
    end

    local function addEventHandler(name, listener)
        if name == "mousereleased" then
            table.insert(__events.mousereleased, listener)
        end
    end

    local runScript = function (name)
        self:runAppScript(name, app)
    end

    APP = {
        threads = {},
        name = app.name,
        version = app.version,
        close = function()
            local count = ram_x - ram_y
            RAM:free(ram_x, count)
            for i = 1, #APP.threads do
                local s = CPU:searchThread(APP.threads[i])
                if s then
                    CPU:removeThread(s)
                end
            end
            APP = nil
            local interface = RAM:read(1)
            interface()
        end,
        hide = function ()
            local interface = RAM:read(1)
            interface()
            APP.isVisible = false
        end,
        show = function ()
            OC.mousereleased = handleMouseReleased
            APP.isVisible = true
        end,
        isVisible = true
    }
    APP.env = {
        addEvent = addEventHandler,
        read = restrictedRead,
        write = restrictedWrite,
        json = require("json"),
        runScript = runScript,
    }

    local envApps = RAM:read(2)
    if envApps[app.name .. ":" .. app.version] then
        envApps[app.name .. ":" .. app.version].close()
    end
    envApps[app.name .. ":" .. app.version] = APP
    RAM:write(2, envApps)

    CPU:addThread(function()
        GPU:clear()
        LDA(app.name)
        DTX(MONITOR.resolution.width/2 - (#A() * 6), 10, A(), {255, 255, 255}, 2)
        DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
        DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
    end)
    self:runAppScript(app.main, app)

    OC.mousereleased = handleMouseReleased

    print("[OS] Successfully launched App: " .. app.name .. ":" .. app.version)
end
----------------------------------
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
                        name = "Console",
                        version = "1.0",
                        main = "main",
                        autoLoad = true,
                        scripts = {
                            main = [[
                                local width = MONITOR.resolution.width
                                local height = MONITOR.resolution.height

                                print(read(0))
                                -- LDA("Loading")
                                -- DTX(width/2 - 6 * #A(), height/2, A(), {255, 0, 0}, 2)
                                -- SLEEP(1)
                                -- DTX(width/2 - 6 * #A(), height/2, A(), {0, 0, 0}, 2)
                                while true do
                                    print(900)
                                    DRE(math.random(1, 390), math.random(1, 290), 10, 10,{255, 255, 255})
                                    SLEEP(1)
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
            RAM:write(2, {}) -- env apps
            write(1, function ()
                GPU:clear()

                LDA({255, 255, 255})
                LDX(kernel.name .. " v" .. kernel.version)
                DTX(10, 10, X(), A(), 2)

                --DRE(0, 0, 400, 300, {255, 255, 255})
            end)
            read(1)()
            for i = 1, #kernel.auto_load_apps, 1 do
                OC:loadApp(kernel.auto_load_apps[i])
            end
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
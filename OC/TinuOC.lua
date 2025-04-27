local json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinyOS",
    is_installing = false,
}

--[[ ----- Ram --------
-1 | файловая система
0 | запущенные приложений
1 | интерфейс ос
2 | окружения запущенный приложений
]]

--[[
is_load   | Загрузочный сектор (MBR)
/trash/ | Корзина

Dekstop | рабочий стол
Documents | документы
Tinu | файлы системы
User | файлы пользователя
User/AppData | файлы приложений
]]

--[[
Архитектура приложения:
name | имя программы
version | версия
icon | таблица цветов иконки 32 на 32
iconText | текст иконки
iconTextColor | цвет текста на иконке
system | системное приложение
company | компания
scripts {} | скрипты
main | оснвоной скрипт
]]

function OC:init(data)
    CPU = data.processor
    data.processor:init()
    MB = data.mother:init(data.processor)
    CPU:setMotherboard(MB)
    RAM = data.ram:init(MB)
    COOLER = data.cooler:init(data.processor, MB)
    MB:attachCooler(COOLER)
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
    FILE_SYSTEM = require("OC.TinuOC.fileSystem")
    FILE_SYSTEM:init(function(success, err)
        if not success then
            print("Init failed:", err)
            return
        end

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
    end)
end

function OC:reboot()
    print("[OS] Rebooting system...")

    local envApps = RAM:read(2)
    for appKey, app in pairs(envApps) do
        if app.close then
            app.close()
        end
    end

    RAM:clear()

    if CPU.cores then
        for core = 1, #CPU.cores, 1 do
            for i = #CPU.cores[core].threads, 1, -1 do
                local thread = CPU.cores[core].threads[i]
                if coroutine.status(thread) ~= "dead" then
                    table.remove(CPU.cores[core].threads, i)
                    self.threadLoad[thread] = nil
                end
            end
        end
    else
        for i = #CPU.threads, 1, -1 do
            local thread = CPU.threads[i]
            if coroutine.status(thread) ~= "dead" then
                table.remove(CPU.threads, i)
                self.threadLoad[thread] = nil
            end
        end
    end

    GPU:clear()
    MONITOR:powerOff()
    MONITOR:powerOn()

    CPU:addThread(function()
        SLEEP(1)

        HDD:read("is_load", function(is_load)
            if is_load == "true" then
                self:startOS()
            else
                self:installDefaultOS()
            end
        end)
    end)
end

function OC:update(dt)
    PSU:update(dt)
    MB:update(dt)
    RAM:update(dt)
    COOLER:update(dt)
    CPU:update(dt)
    GPU:update(dt)
    MONITOR:update(dt)
    HDD:update(dt)
end

function OC:draw()
    MONITOR:draw()
end

-- Приложения --------------------
function OC:uninstallApp(appName, callback)
    if type(appName) ~= "string" or appName == "" then
        print("[OS] Error: Invalid app name")
        if callback then callback(false, "Invalid app name") end
        return
    end

    if appName:lower() == "console" or appName:lower() == "files" then
        print("[OC] Error: Permission denied for uninstall app: "..appName)
        callback(false)
        return
    end

    local appIndex = "app_" .. appName:lower():gsub("[^%w]", "_")

    local envApps = RAM:read(2)
    local runningAppKey = nil

    for key, app in pairs(envApps) do
        if key:match("^"..appName..":") then
            runningAppKey = key
            break
        end
    end

    if runningAppKey then
        envApps[runningAppKey].close()
        print("[OS] App '"..appName.."' was running and has been closed")
    end

    local file = FILE_SYSTEM:open("Tinu/apps.json", "r")
    file:read(function(appsJson)
        file.close()
        local apps = json.decode(appsJson) or {}
        local found = false
        local newApps = {}

        for i, index in ipairs(apps) do
            if index == appIndex then
                found = true
            else
                table.insert(newApps, index)
            end
        end

        if not found then
            print("[OS] Error: App '"..appName.."' not found")
            if callback then callback(false, "App not found") end
            return
        end

        file = FILE_SYSTEM:open("Tinu/apps.json", "w")
        file:write(json.encode(newApps), function(success)
            file.close()
            if not success then
                print("[OS] Error: Failed to update apps list")
                if callback then callback(false, "Failed to update apps list") end
                return
            end

            file = FILE_SYSTEM:open("User/AppData/"..appIndex.."/app.json", "r")
            file:read(function (app)
                app = json.decode(app)
                file = FILE_SYSTEM:open("Dekstop/"..app.name..".app", "w")
                file:remove(function ()
                    file = FILE_SYSTEM:open("User/AppData/"..appIndex.."/app.json", "w")
                    file:remove(function(success)
                        if success then
                            print("[OS] App '"..appName.."' uninstalled successfully")
                            HDD:saveToFile()
                            if callback then callback(true) end
                        else
                            print("[OS] Error: Failed to remove app data")
                            if callback then callback(false, "Failed to remove app data") end
                        end
                    end, true)
                end, true)
            end)
        end)
    end)
end

function OC:installApp(appData, callback)
    if type(appData) ~= "table" or not appData.name or not appData.main or not appData.scripts then
        print("[OS] Error: Invalid app data structure")
        return false
    end
    if appData.system then
        if not OC.is_installing then
            print("[OC] Error: Permission denied for install app: "..appData.name)
            callback(false)
            return
        end
    end

    if (appData.name:lower() == "console" or appData.name:lower() == "files") and not OC.is_installing then
        print("[OC] Error: Permission denied for install app: "..appData.name)
        callback(false)
        return
    end

    local appIndex = "app_" .. appData.name:lower():gsub("[^%w]", "_")

    local file = FILE_SYSTEM:open("Tinu/apps.json", "r")
    file:read(function (value)
        local apps = json.decode(value)
        table.insert(apps, appIndex)
        file.close()
        file = FILE_SYSTEM:open("Tinu/apps.json", "w")
        file:write(json.encode(apps), function (success)
            if not success then
                print("[OS] Error: Failed to install app '" .. appData.name .. "'")
                return
            end
            file.close()
            FILE_SYSTEM:mkDir("User/AppData/"..appIndex, function (success)
                if success then
                    file = FILE_SYSTEM:open("User/AppData/"..appIndex.."/app.json", "w")
                    file:write(json.encode(appData), function (success)
                        if success then
                            file = FILE_SYSTEM:open("Dekstop/"..appData.name..".app", "w")
                            file:write("User/AppData/"..appIndex, function ()
                                print("[OS] App '" .. appData.name .. "' installed successfully")
                                HDD:saveToFile()
                                if callback then callback(true) end
                            end)
                        else
                            print("[OS] Error: Failed to install app '" .. appData.name .. "'")
                            if callback then callback(false) end
                        end
                    end)
                else
                    print("[OS] Error: Failed to install app '" .. appData.name .. "'")
                    if callback then callback(false) end
                end
            end)
        end)
    end)

    return true
end

function OC:loadApp(appIndex, callback)
    local apps = RAM:read(0)
    local app = apps[appIndex]
    if app then
        self:runApp(app, appIndex)
        if callback then callback(app) end
        return
    end

    local file = FILE_SYSTEM:open("User/AppData/"..appIndex.."/app.json", "r")
    file:read(function(appJson)
        file.close()
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
        self:runApp(app, appIndex)
        if callback then callback(app) end
    end)
end

function OC:runAppScript(scriptName, app)
    if not app.scripts or not app.scripts[scriptName] then
        print("[OS] Error: Script '" .. scriptName .. "' not found")
        return false
    end
    local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")

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

        ]=] .. (not app.system and [=[
        local OC = {
            version = OC.version,
            name = OC.name,
            uninstallApp = function(self, appName, callback)
                if appName:lower() == "console" or appName:lower() == "files" then
                    print("[OC] Error: Permission denied for uninstall app: "..appName)
                    callback(false)
                    return
                end
                OC:uninstallApp(appName, callback)
            end,
            installApp = function(self, appData, callback)
                OC:installApp(appData, callback)
            end,
            reboot = function()
                OC:reboot()
            end
        }

        local FILE_SYSTEM = {
            version = FILE_SYSTEM.version,
            getTemp = FILE_SYSTEM.getTemp,
            saveTemp = FILE_SYSTEM.saveTemp,
            open = function(self, path, mode)
                local function split(str, delimiter)
                    local result = {}
                    for part in str:gmatch("[^" .. delimiter .. "]+") do
                        table.insert(result, part)
                    end
                    return result
                end
                local __path = split(path, "/")
                if __path[1] ~= "Dekstop" then
                    path = "User/AppData/" .. "]=].. appIndex ..[=[" .. "/" .. path
                end

                return FILE_SYSTEM:open(path, mode)
            end,
            mkDir = function(self, path, callback)
                local function split(str, delimiter)
                    local result = {}
                    for part in str:gmatch("[^" .. delimiter .. "]+") do
                        table.insert(result, part)
                    end
                    return result
                end
                local __path = split(path, "/")
                if __path[1] ~= "Dekstop" then
                    path = "User/AppData/" .. "]=].. appIndex ..[=[" .. "/" .. path
                end
                return FILE_SYSTEM:mkDir(path, callback)
            end,
            rmDir = function(self, path, callback)
                local function split(str, delimiter)
                    local result = {}
                    for part in str:gmatch("[^" .. delimiter .. "]+") do
                        table.insert(result, part)
                    end
                    return result
                end
                local __path = split(path, "/")
                if __path[1] ~= "Dekstop" then
                    path = "User/AppData/" .. "]=].. appIndex ..[=[" .. "/" .. path
                end
                FILE_SYSTEM:rmDir(path, callback)
            end,
            getDirFiles = function(self, path, callback)
                local function split(str, delimiter)
                    local result = {}
                    for part in str:gmatch("[^" .. delimiter .. "]+") do
                        table.insert(result, part)
                    end
                    return result
                end
                local __path = split(path, "/")
                if __path[1] ~= "Dekstop" then
                    path = "User/AppData/" .. "]=].. appIndex ..[=[" .. "/" .. path
                end
                FILE_SYSTEM:getDirFiles(path, callback)
            end,
        }

        local HDD = {
            model = HDD.model,
            version = HDD.version,
            read = function(self, ...)
                HDD:read(...)
            end,
            write = function(self, address, ...)
                if address == "Tinu" or address == "User/AppData" or address == "is_load" then
                    print("[OC] Error: Permission denied for address: "..address)
                    return
                end
                HDD:write(address, ...)
            end,
            getInfo = function()
                return HDD:getInfo()
            end,
            saveToFile = function(self, filename)
                HDD:saveToFile(filename)
            end,
            loadFromFile = function()
                print("[OC] Error: Permission denied "..loadFromFile)
            end,
        }

        local RAM = {
            model = RAM.model,
            version = RAM.version,
            read = function(self, address)
                return RAM:read(address)
            end,
            getInfo = function()
                return RAM:getInfo()
            end,
            write = function()
                print("[OC] Error: Permission denied RAM:write, please used function write(address, data)")
            end,
        }
    
        local MONITOR = {
            model = MONITOR.model,
            version = MONITOR.version,
            powerOn = function(self)
                MONITOR:powerOn()
            end,
            powerOff = function(self)
                MONITOR:powerOff()
            end,
            getInfo = function(self)
                return MONITOR:getInfo()
            end,
            applyColorEffects = function(self, r, g, b)
                MONITOR:applyColorEffects(r, g, b)
            end,
            setBacklight = function(self, level)
                MONITOR:setBacklight(level)
            end,
            setContrast = function(self, level)
                MONITOR:setContrast(level)
            end,
            setBrightness = function(self, level)
                MONITOR:setBrightness(level)
            end,
            resolution = MONITOR.resolution,
            colorDepth = MONITOR.colorDepth,
        }

        local PSU = {
            model = PSU.model,
            version = PSU.version,
            getInfo = function()
                return PSU:getInfo()
            end
        }

        local COOLER = {
            model = COOLER.model,
            version = COOLER.version,
            setManualRPM = function(self, rpm)
                COOLER:setManualRPM(rpm)
            end,
            getInfo = function(self)
                return COOLER:getInfo()
            end
        }

        local MB = {
            model = MB.model,
            version = MB.version,
        }

        local GPU = {
            model = GPU.model,
            version = GPU.version,
            clear = function(self)
                GPU:clear()
            end,
            getCore = function(self)
                return GPU:getCore()
            end,
            getInfo = function(self)
                return GPU:getInfo()
            end
        }


        local CPU = {
            model = CPU.model,
            version = CPU.version,
            getInfo = function(self)
                return CPU:getInfo()
            end,
            countActiveThreads = function(self)
                return CPU:countActiveThreads()
            end,
            getThreadLoads = function(self)
                return CPU:getThreadLoads()
            end,
            searchThread = function(self, co)
                return CPU:searchThread(co)
            end,
            removeThread = function(self, index)
                CPU:removeThread(index)
            end,
            addThread = function(self, func)
                CPU:addThread(func)
            end
        }

        local _G = {
            os = os,
            math = math,
            io = io,
            assert = assert,
            string = string,
            arg = arg,
            bit = bit,
            debug = debug,
            table = table,
            type = type,
            next = next,
            pairs = pairs,
            ipairs = ipairs,
            getmetatable = getmetatable,
            setmetatable = setmetatable,
            rawget = rawget,
            rawset = rawset,
            rawequal = rawequal,
            unpack = unpack,
            select = select,
            tonumber = tonumber,
            tostring = tostring,
            error = error,
            pcall = pcall,
            xpcall = xpcall,
        }
    ]=] or "")..
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
        mousereleased = {},
        keypressed = {}
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

    local function handleKeypressed(key, scancode, isrepeat)
        for i = 1, #__events.keypressed do
            __events.keypressed[i](key, scancode, isrepeat)
        end
    end

    local function addEventHandler(name, listener)
        if name == "mousereleased" then
            table.insert(__events.mousereleased, listener)
        elseif name == "keypressed" then
            table.insert(__events.keypressed, listener)
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
            local count = ram_y - ram_x
            RAM:free(ram_x, count + 1)
            for i = 1, #APP.threads do
                local s = CPU:searchThread(APP.threads[i])
                if s then
                    CPU:removeThread(s)
                end
            end
            APP = nil
            local envApps = RAM:read(2)
            if envApps[app.name .. ":" .. app.version] then
                envApps[app.name .. ":" .. app.version] = nil
            end
            RAM:write(2, envApps)
            local interface = RAM:read(1)
            interface()
        end,
        hide = function ()
            OC.mousereleased = nil
            OC.keypressed = nil
            APP.frame_buffer = json.encode(GPU.frame_buffer)
            local interface = RAM:read(1)
            interface()
            for i = 1, #APP.threads do
                local s = CPU:searchThread(APP.threads[i])
                if s then
                    CPU:removeThread(s)
                end
            end
            APP.isVisible = false
            local envApps = RAM:read(2)
            envApps[app.name .. ":" .. app.version] = APP
            RAM:write(2, envApps)
        end,
        show = function ()
            OC.mousereleased = handleMouseReleased
            OC.keypressed = handleKeypressed
            GPU.frame_buffer = json.decode(APP.frame_buffer)
            APP.frame_buffer = nil
            for i = 1, #APP.threads do
                local success, co = CPU:addThread(function ()end)
                if success then
                    local s, core = CPU:searchThread(co)
                    if core then
                        CPU.cores[core].threads[s] = APP.threads[i]
                    elseif s then
                        CPU.threads[s] = APP.threads[i]
                    else
                        print("[OS] Error: App is missing resume processes")
                    end
                else
                    print("[OS] Error: App is missing resume processes")
                end
            end
            local envApps = RAM:read(2)
            envApps[app.name .. ":" .. app.version] = APP
            RAM:write(2, envApps)
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
    OC.keypressed = handleKeypressed


    print("[OS] Successfully launched App: " .. app.name .. ":" .. app.version)
end
----------------------------------
function OC:installDefaultOS()
    OC.is_installing = true
    print("[OS] Installing default OS...")

    FILE_SYSTEM:mkDir("Tinu", function (success, err)
        if not success then
            print("[OS installer] Error: "..err, "Tinu")
            return
        end
        FILE_SYSTEM:mkDir("Dekstop", function (success, err)
            if not success then
                print("[OS installer] Error: "..err, "Dekstop")
                return
            end
            FILE_SYSTEM:mkDir("Documents", function (success, err)
                if not success then
                    print("[OS installer] Error: "..err, "Documents")
                    return
                end
                FILE_SYSTEM:mkDir("User", function (success, err)
                    if not success then
                        print("[OS installer] Error: "..err, "User")
                        return
                    end
                    FILE_SYSTEM:mkDir("User/AppData", function (success, err)
                        if not success then
                            print("[OS installer] Error: "..err, "User/AppData")
                            return
                        end

                        local file = FILE_SYSTEM:open("Tinu/core.json", "w")
                        file:write(json.encode({
                            version = self.version,
                            name = self.name,
                        }), function (success, err)
                            if not success then
                                print("[OS installer] Error: "..err, "Tinu/core.json")
                                return
                            end

                            file:close()
                            file = nil

                            local file = FILE_SYSTEM:open("Tinu/apps.json", "w")
                            file:write(json.encode({}), function (success, err)
                                if not success then
                                    print("[OS installer] Error: "..err, "Tinu/apps.json")
                                    return
                                end

                                file:close()
                                file = nil

                                print("[OS installer] Installing system apps")
                                OC:installApp({
                                    name = "Console",
                                    version = "1.0",
                                    main = "main",
                                    iconText = "CMD",
                                    iconTextColor = {255, 255, 255},
                                    icon = json.decode('[[[70,110,200],[68,107,197],[67,106,196],[66,105,195],[65,103,193],[64,102,192],[63,101,191],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[58,95,185],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[47,80,170],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[255,95,90],[255,95,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[58,95,185],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[47,80,170],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[255,95,90],[255,95,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[47,80,170],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[255,95,90],[255,95,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[57,93,183],[56,92,182],[55,91,181],[180,210,255],[54,88,178],[53,87,177],[52,86,176],[180,210,255],[50,83,173],[49,82,172],[48,81,171],[180,210,255],[46,78,168],[45,77,167],[44,76,166],[180,210,255],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[58,95,185],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[47,80,170],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[58,95,185],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[47,80,170],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[47,80,170],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[90,200,90],[90,200,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[57,93,183],[56,92,182],[55,91,181],[180,210,255],[54,88,178],[53,87,177],[52,86,176],[180,210,255],[50,83,173],[49,82,172],[48,81,171],[180,210,255],[46,78,168],[45,77,167],[44,76,166],[180,210,255],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[90,200,90],[90,200,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[58,95,185],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[47,80,170],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[90,200,90],[90,200,90],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[58,95,185],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[47,80,170],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[47,80,170],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[57,93,183],[56,92,182],[55,91,181],[180,210,255],[54,88,178],[53,87,177],[52,86,176],[180,210,255],[50,83,173],[49,82,172],[48,81,171],[180,210,255],[46,78,168],[45,77,167],[44,76,166],[180,210,255],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[58,95,185],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[47,80,170],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[58,95,185],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[47,80,170],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[47,80,170],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[100,140,220],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[58,95,185],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[47,80,170],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[180,210,255],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[180,210,255],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[180,210,255],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[57,93,183],[56,92,182],[55,91,181],[180,210,255],[54,88,178],[53,87,177],[52,86,176],[180,210,255],[50,83,173],[49,82,172],[48,81,171],[180,210,255],[46,78,168],[45,77,167],[44,76,166],[180,210,255],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[180,210,255],[180,210,255],[57,93,183],[56,92,182],[180,210,255],[55,90,180],[54,88,178],[53,87,177],[180,210,255],[51,85,175],[50,83,173],[49,82,172],[180,210,255],[180,210,255],[46,78,168],[45,77,167],[180,210,255],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[180,210,255],[59,96,186],[180,210,255],[57,93,183],[180,210,255],[55,91,181],[55,90,180],[54,88,178],[180,210,255],[52,86,176],[51,85,175],[50,83,173],[180,210,255],[48,81,171],[180,210,255],[46,78,168],[180,210,255],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[180,210,255],[56,92,182],[55,91,181],[55,90,180],[180,210,255],[53,87,177],[52,86,176],[51,85,175],[180,210,255],[49,82,172],[48,81,171],[180,210,255],[180,210,255],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[180,210,255],[57,93,183],[56,92,182],[55,91,181],[180,210,255],[54,88,178],[53,87,177],[52,86,176],[180,210,255],[50,83,173],[49,82,172],[48,81,171],[180,210,255],[46,78,168],[45,77,167],[44,76,166],[180,210,255],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[69,108,198],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[30,50,120],[100,140,220],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]],[[70,110,200],[68,107,197],[67,106,196],[66,105,195],[65,103,193],[64,102,192],[63,101,191],[62,100,190],[61,98,188],[60,97,187],[59,96,186],[58,95,185],[57,93,183],[56,92,182],[55,91,181],[55,90,180],[54,88,178],[53,87,177],[52,86,176],[51,85,175],[50,83,173],[49,82,172],[48,81,171],[47,80,170],[46,78,168],[45,77,167],[44,76,166],[43,75,165],[42,73,163],[41,72,162],[40,71,161],[40,70,160]]]'),
                                    system = true,
                                    scripts = {
                                        main = [[
local logStart = 0
local command = ""
local cursorPos = 1
local cursorBlink = 0
local cursorVisible = true
            
local CONSOLE_LOG_SIZE = 100
local CONSOLE_LINE_HEIGHT = 16
local CONSOLE_MARGIN = 10

local draw = function()
    GPU:clear()
            
    local text = "Console"
    DTX(MONITOR.resolution.width/2 - (#text * 6), 10, text, {255, 255, 255}, 2)
    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
            
    local logs = read(1) == 0 and {} or read(1)
    local startY = CONSOLE_MARGIN
    local visibleLines = math.floor((MONITOR.resolution.height - (CONSOLE_MARGIN * 2 + CONSOLE_LINE_HEIGHT)) / CONSOLE_LINE_HEIGHT)
    logStart = math.max(1, #logs - visibleLines + 1)
                                                
    for i = logStart, #logs do
        local log = logs[i]
        DTX(CONSOLE_MARGIN, startY, log.text, log.color, 1)
        startY = startY + CONSOLE_LINE_HEIGHT
    end
                                                
    DTX(CONSOLE_MARGIN, MONITOR.resolution.height - (CONSOLE_MARGIN + CONSOLE_LINE_HEIGHT) + 3, "> " .. command, {255, 255, 255}, 1)
            
    cursorBlink = cursorBlink + 1
    if cursorBlink >= 20 then
        cursorVisible = not cursorVisible
        cursorBlink = 0
    end
                                                
    if cursorVisible then
        local cursorX = CONSOLE_MARGIN + (#("> " .. string.sub(command, 1, cursorPos-1)) * 6)
        DRE(cursorX, MONITOR.resolution.height - (CONSOLE_MARGIN + CONSOLE_LINE_HEIGHT) + 3, 
            2, (CONSOLE_LINE_HEIGHT - 6), {255, 255, 255})
    end
end
                                
local function addLog(text, color)
    color = color or {255, 255, 255}
    local logs = read(1) == 0 and {} or read(1)
    table.insert(logs, {text = text, color = color})
            
    if #logs > CONSOLE_LOG_SIZE then
        table.remove(logs, 1)
    end
    
    write(1, logs)
    draw()
end
            
local function executeCommand(cmd)
    addLog("> " .. cmd, {0, 255, 0})
            
    command = ""
    cursorPos = 1
            
    if cmd == "clear" then
        write(1, {})
    elseif cmd == "help" then
        addLog("Available commands:", {255, 255, 0})
        addLog("clear - Clear console", {200, 200, 200})
        addLog("help - Show this help", {200, 200, 200})
        addLog("apps - List installed apps", {200, 200, 200})
        addLog("uninstall nameApp - Delete installed app", {200, 200, 200})
        addLog("time - System time", {200, 200, 200})
        addLog("ram, cpu, gpu, psu, mb,", {200, 200, 200})
        addLog("cooler, monitor, disk,", {200, 200, 200})
        addLog("shutdown - Completion of work", {200, 200, 200})
        addLog("reboot - Reboot system", {200, 200, 200})
    elseif string.sub(cmd, 1, 10) == "uninstall " then
        local name = string.gsub(cmd, "uninstall ", "")
        OC:uninstallApp(name, function(success)
            if success then
                addLog("[OS] Success: uninstall "..name, {200, 200, 200})
            else
                addLog("[OS] Error: uninstall "..name, {200, 200, 200})
            end
        end)
    elseif cmd == "ram" then
        local info = RAM:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "time" then
        addLog("Time: " .. os.time(), {200, 200, 200})
    elseif cmd == "shutdown" then
        os.exit()
    elseif cmd == "reboot" then
        OC:reboot()
    elseif cmd == "cpu" then
        local info = CPU:getInfo()
        for key, value in pairs(info) do
            if type(value == "table") then
                value = json.encode(value)
            end
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "gpu" then
        local info = GPU:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "psu" then
        local info = PSU:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "mb" then
        addLog("Model: "..MB.model, {200, 200, 200})
        addLog("Version: "..MB.version, {200, 200, 200})
    elseif cmd == "cooler" then
        local info = COOLER:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "monitor" then
        local info = MONITOR:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "disk" then
        local info = HDD:getInfo()
        for key, value in pairs(info) do
            addLog(key..": "..tostring(value), {200, 200, 200})
        end
    elseif cmd == "apps" then
        local file = FILE_SYSTEM:open("Tinu/apps.json", "r")
        file:read(function (apps)
            file.close()
            apps = json.decode(apps)
            addLog("Installed apps (" .. #apps .. "):", {255, 255, 0})
            for i, appIndex in ipairs(apps) do
                file = FILE_SYSTEM:open("User/AppData/"..appIndex.."/app.json", "r")
                file:read(function(appJson)
                    file.close()
                    if not appJson or appJson == "" then
                        print("[OS] Error: App not found - " .. appIndex)
                        return
                    end
            
                    local app = json.decode(appJson)
                    if app then
                        addLog(string.format("%d. %s v%s", i, app.name, app.version), {200, 200, 200})
                    end
                end)
            end
        end)
    
    else
        addLog("Unknown command: " .. cmd .. ", 'help' command information.", {255, 100, 100})
    end
end
            
addEvent("keypressed", function(key)
    if key == "return" then
        if #command > 0 then
            executeCommand(command)
        end
    elseif key == "backspace" then
        if cursorPos > 1 then
            command = string.sub(command, 1, cursorPos-2) .. string.sub(command, cursorPos)
            cursorPos = cursorPos - 1
        end
    elseif key == "left" then
        if cursorPos > 1 then
            cursorPos = cursorPos - 1
        end
    elseif key == "right" then
        if cursorPos <= #command then
            cursorPos = cursorPos + 1
        end
    elseif key == "home" then
        cursorPos = 1
    elseif key == "end" then
        cursorPos = #command + 1
    elseif key == "space" then
        command = string.sub(command, 1, cursorPos-1) .. " " .. string.sub(command, cursorPos)
        cursorPos = cursorPos + 1
    elseif #key == 1 then
        command = string.sub(command, 1, cursorPos-1) .. key .. string.sub(command, cursorPos)
        cursorPos = cursorPos + 1
    end
                                                
    cursorBlink = 0
    cursorVisible = true
    draw()
end)
            
draw()
            
while true do
    SLEEP(0.05)
end
                                        ]]
                                    }
                                }, function()
                                    OC:installApp({
                                        name = "Files",
                                        version = "1.0",
                                        main = "main",
                                        iconText = "File",
                                        icon = json.decode('[[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]]]'),
                                        system = true,
                                        scripts = {
                                            main = [[
local function displayFiles()
    GPU:clear()
                
    LDA({255, 255, 255})
    LDX("File Explorer")
    DTX(10, 10, X(), A(), 2)
    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
    local storage = HDD:getAllStorage()
    if not storage or type(storage) ~= "table" or next(storage) == nil then
        LDX("No files found")
        DTX(MONITOR.resolution.width/2 - (#X() * 6), MONITOR.resolution.height/2, X(), {255, 255, 255}, 2)
        return
    end
    local startX = 20
    local startY = 50
    local lineHeight = 20
    local margin = 10
    LDX("Files List:")
    DTX(startX, startY, X(), {255, 255, 255}, 1)
    APP.fileNames = {}
    for name in pairs(storage) do
        table.insert(APP.fileNames, name)
    end
    table.sort(APP.fileNames)
    APP.fileScrollPos = APP.fileScrollPos or 0
    APP.maxVisibleFiles = math.floor((MONITOR.resolution.height - startY - 50) / lineHeight)
    APP.filePositions = {}
    for i = 1, math.min(APP.maxVisibleFiles, #APP.fileNames - APP.fileScrollPos) do
        local fileName = APP.fileNames[i + APP.fileScrollPos]
        local yPos = startY + (i * lineHeight)
        LDX(fileName)
        DTX(startX + margin, yPos, X(), {200, 200, 200}, 1)
        APP.filePositions[fileName] = {x = startX + margin, y = yPos, width = #fileName * 6, height = lineHeight}
    end
    if #APP.fileNames > APP.maxVisibleFiles then
        local scrollText = string.format("%d/%d", math.min(APP.fileScrollPos + 1, #APP.fileNames), #APP.fileNames)
        LDX(scrollText)
        DTX(MONITOR.resolution.width - 50, MONITOR.resolution.height - 30, X(), {150, 150, 150}, 1)
        
        LDX("up/down: Scroll")
        DTX(10, MONITOR.resolution.height - 30, X(), {150, 150, 150}, 1)
    end
end
local function displayFileContent(fileName, content)
    GPU:clear()
    LDA({255, 255, 255})
    LDX("File Content: " .. fileName)
    DTX(10, 10, X(), A(), 2)
    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
    local startX = 20
    local startY = 30
    local lineHeight = 20
    local lines = {}
    write(2, lines)
    local max_chars_per_line = math.floor((MONITOR.resolution.width - 20) / 6)
    for line in content:gmatch("[^\r\n]+") do
        while #line > max_chars_per_line do
            local chunk = line:sub(1, max_chars_per_line)
            table.insert(lines, chunk)
            line = line:sub(max_chars_per_line + 1)
        end
        if #line > 0 then
            table.insert(lines, line)
        end
    end
    APP.scrollPos = 0
    APP.maxVisibleLines = math.floor((MONITOR.resolution.height - 80) / lineHeight)
    for i = 1, math.min(APP.maxVisibleLines, #lines - APP.scrollPos) do
        local yPos = startY + ((i-1) * lineHeight)
        LDX(lines[i + APP.scrollPos])
        DTX(startX, yPos, X(), {200, 200, 200}, 1)
    end
    LDX("up/down: Scroll  Esc: Exit  R: Refresh")
    DTX(10, MONITOR.resolution.height - 50, X(), {150, 150, 150}, 1)
    LDX("Back to Files")
    DTX(10, MONITOR.resolution.height - 30, X(), {0, 255, 0}, 1)
    APP.backButton = {x = 10, y = MONITOR.resolution.height - 30, width = #("Back to Files") * 6, height = 20}
    write(2, lines)
end
local is_block_event = false
addEvent("keypressed", function(key)
    if is_block_event then
        return
    end
    if key == "escape" then
        APP.close()
    elseif key == "r" then
        write(2, 0)
        displayFiles()
    elseif key == "up" or key == "down" then
        if read(2) ~= 0 then
            if key == "up" and APP.scrollPos > 0 then
                APP.scrollPos = APP.scrollPos - 1
            elseif key == "down" and APP.scrollPos < #read(2) - APP.maxVisibleLines then
                APP.scrollPos = APP.scrollPos + 1
            end
            GPU:clear()
            LDA({255, 255, 255})
            LDX("File Content: " .. APP.currentFile)
            DTX(10, 10, X(), A(), 2)
            DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
            DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
            local startX = 20
            local startY = 30
            local lineHeight = 20
            for i = 1, math.min(APP.maxVisibleLines, #read(2) - APP.scrollPos) do
                local yPos = startY + ((i-1) * lineHeight)
                LDX(read(2)[i + APP.scrollPos])
                DTX(startX, yPos, X(), {200, 200, 200}, 1)
            end
            LDX("up/down: Scroll  Esc: Exit  R: Refresh")
            DTX(10, MONITOR.resolution.height - 50, X(), {150, 150, 150}, 1)
            LDX("Back to Files")
            DTX(10, MONITOR.resolution.height - 30, X(), {0, 255, 0}, 1)
        else
            if key == "up" and APP.fileScrollPos > 0 then
                APP.fileScrollPos = APP.fileScrollPos - 1
            elseif key == "down" and APP.fileScrollPos < #APP.fileNames - APP.maxVisibleFiles then
                APP.fileScrollPos = APP.fileScrollPos + 1
            end
            displayFiles()
        end
    end
end)
addEvent("mousereleased", function(x, y)
    if is_block_event then
        return
    end
    if APP.backButton and x >= APP.backButton.x and x <= APP.backButton.x + APP.backButton.width and
       y >= APP.backButton.y and y <= APP.backButton.y + APP.backButton.height then
        write(2, 0)
        displayFiles()
        return
    end
    for fileName, pos in pairs(APP.filePositions) do
        if x >= pos.x and x <= pos.x + pos.width and y >= pos.y and y <= pos.y + pos.height then
            GPU:clear()
            LDX("Loadind content...")
            DTX(MONITOR.resolution.width/2 - #X() * 4, MONITOR.resolution.height/2, X(), {255, 255, 255})
            is_block_event = true
            HDD:read(fileName, function(content)
                is_block_event = false
                APP.currentFile = fileName
                displayFileContent(fileName, content)
                return
            end)
        end
    end
end)
APP.filePositions = {}
APP.backButton = nil
write(2, 0) -- lines
APP.scrollPos = 0
APP.maxVisibleLines = 0
APP.fileNames = {}
APP.fileScrollPos = 0
APP.maxVisibleFiles = 0
APP.currentFile = ""
displayFiles()
while true do
    SLEEP(0.05)
end
                                            ]]
                                        }
                                    }, function()
                                        OC.is_installing = false
                                        print("[OS] Default OS installed successfully")
                                        HDD:saveToFile()
                                        self:startOS()
                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

function OC:startOS()
    local init = function (kernel)
        local file = FILE_SYSTEM:open("Dekstop/test.txt", "w")
        file:write("100", function ()end)

        CPU:addThread(function ()
            write(0, {}) -- apps
            RAM:write(2, {}) -- env apps
            write(1, function ()
                GPU:clear()
        
                LDA({255, 255, 255})
                LDX(kernel.name .. " v" .. kernel.version)
                DTX(10, 10, X(), A(), 2)
        
                local iconSize = 32
                local margin = 20
                local textHeight = 20
                local startX = margin
                local startY = margin + 40
                local itemsPerRow = math.floor((MONITOR.resolution.width - margin * 2) / (iconSize + margin))
        
                local file = FILE_SYSTEM:getDirFiles("Dekstop", function (files)
                    local i = 0
                    local appPositions = {}
                    
                    for path, value in pairs(files) do
                        local file = FILE_SYSTEM:open("Dekstop/"..path, "r")
                        i = i + 1
                        file:read(function (data)
                            if data then
                                local row = math.floor((i-1) / itemsPerRow)
                                local col = (i-1) % itemsPerRow
                                local x = startX + col * (iconSize + margin)
                                local y = startY + row * (iconSize + margin + textHeight)
        
                                if file.fileExt == "app" then
                                    local fileApp = FILE_SYSTEM:open(data .. "/app.json", "r")
                                    fileApp:read(function (appJson)
                                        local app = json.decode(appJson)
        
                                        if app then
                                            local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                                            appPositions[i] = {
                                                x = x,
                                                y = y,
                                                width = iconSize,
                                                height = iconSize,
                                                appPath = data,
                                                appData = app,
                                                appIndex = appIndex
                                            }
        
                                            if app.icon then
                                                DRM(x, y, app.icon)
                                            else
                                                LDA({150, 150, 150})
                                                DRE(x, y, iconSize, iconSize, A())
                                            end
        
                                            local envApps = RAM:read(2)
                                            local appKey = app.name .. ":" .. app.version
                                            if envApps[appKey] then
                                                LDA({0, 255, 0})
                                                DRE(x + iconSize - 5, y + iconSize - 5, 5, 5, A())
                                            end
        
                                            if app.iconTextColor then
                                                LDA(app.iconTextColor)
                                            else
                                                LDA({0,0,0})
                                            end
                                            if app.system then
                                                LDX("SYS")
                                                DTX(x + 1, y + iconSize - 8, X(), A(), 1)
                                            end
                                            if app.iconText then
                                                LDX(app.iconText)
                                            else
                                                LDX("Icon")
                                            end
                                            DTX(x + iconSize/2 - (#X() * 3), y + iconSize/2 - 3, X(), A(), 1)
        
                                            LDA({255, 255, 255})
                                            LDX(app.name)
                                            DTX(x + iconSize/2 - (#X() * 3), y + iconSize + 5, X(), A(), 1)
                                        end
                                    end)
                                else
                                    LDA({150, 150, 150})
                                    DRE(x, y, iconSize, iconSize, A())
        
                                    LDA({0,0,0})
                                    LDX(file.fileExt)
                                    DTX(x + iconSize/2 - (#X() * 3), y + iconSize/2 - 3, X(), A(), 1)
        
                                    LDA({255, 255, 255})
                                    LDX(file.fileName)
                                    DTX(x + iconSize/2 - (#X() * 3), y + iconSize + 5, X(), A(), 1)
                                end
                            end
                        end)
                    end
        
                    OC.mousereleased = function (x, y)
                        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
                        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
                        local scale = math.min(scaleX, scaleY)
                        x, y = x / scale, y / scale

                        for _, app in pairs(appPositions) do
                            if x >= app.x and x <= app.x + app.width and
                               y >= app.y and y <= app.y + app.height then
                                
                                local envApps = RAM:read(2)
                                local appKey = app.appData.name .. ":" .. app.appData.version
                                
                                if envApps[appKey] then
                                    envApps[appKey].show()
                                else
                                    OC:loadApp(app.appIndex)
                                end
                                return
                            end
                        end
                    end
                end)
            end)
            read(1)()
        end)
    end

    local file = FILE_SYSTEM:open("Tinu/core.json", "r")
    file:read(function (value, err)
        if not value then
            print("[OS] Error: Invalid kernel data ", err)
            self:installDefaultOS()
            return
        end

        local kernel = json.decode(value)
        if kernel then
            init(kernel)
        end
    end)
end

return OC
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

    HDD:read("apps", function(appsJson)
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

        HDD:write("apps", json.encode(newApps), function(success)
            if not success then
                print("[OS] Error: Failed to update apps list")
                if callback then callback(false, "Failed to update apps list") end
                return
            end

            HDD:write("apps/"..appIndex, "", function(success)
                if success then
                    print("[OS] App '"..appName.."' uninstalled successfully")
                    HDD:saveToFile()
                    if callback then callback(true) end
                else
                    print("[OS] Error: Failed to remove app data")
                    if callback then callback(false, "Failed to remove app data") end
                end
            end)
        end)
    end)
end

function OC:installApp(appData, callback)
    if type(appData) ~= "table" or not appData.name or not appData.main or not appData.scripts then
        print("[OS] Error: Invalid app data structure")
        return false
    end

    local appIndex = "app_" .. appData.name:lower():gsub("[^%w]", "_")

    HDD:read("apps", function (apps)
        apps = json.decode(apps) or {}
        table.insert(apps, appIndex)
        HDD:write("apps", json.encode(apps), function (success)
            if not success then
                print("[OS] Error: Failed to install app '" .. appData.name .. "'")
                return
            end
            HDD:write("apps/" .. appIndex, json.encode(appData), function(success)
                if success then
                    print("[OS] App '" .. appData.name .. "' installed successfully")
                    HDD:saveToFile()
                    if callback then callback(true) end
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
        self:runApp(app, appIndex)
        if callback then callback(app) end
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

        local OC = {
            version = OC.version,
            name = OC.name,
            uninstallApp = function(self, appName, callback)
                if appName:lower() == "console" then
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

        local HDD = {
            model = HDD.model,
            version = HDD.version,
            read = function(self, ...)
                HDD:read(...)
            end,
            write = function(self, address, ...)
                if address == "core" or address == "apps" or address == "is_load" then
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
    print("[OS] Installing default OS...")

    local kernel = {
        version = self.version,
        name = self.name,
    }

    HDD:write("apps", "{}", function (success)
        if success then
            local kernelData = json.encode(kernel)
            HDD:write("core", kernelData, function(success)
                if success then
                    print("[OS] Installing app - Console")
                    OC:installApp({
                        name = "Console",
                        version = "1.0",
                        main = "main",
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
                    
                                local function addLog(text, color)
                                    color = color or {255, 255, 255}
                                    local logs = read(1) == 0 and {} or read(1)
                                    table.insert(logs, {text = text, color = color})

                                    if #logs > CONSOLE_LOG_SIZE then
                                        table.remove(logs, 1)
                                    end
                                    
                                    write(1, logs)
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
                                        addLog("ram - Show RAM information", {200, 200, 200})
                                        addLog("cpu - Show CPU information", {200, 200, 200})
                                        addLog("gpu - Show GPU information", {200, 200, 200})
                                        addLog("psu - Show PSU information", {200, 200, 200})
                                        addLog("mb - Show MB information", {200, 200, 200})
                                        addLog("cooler - Show COOLER information", {200, 200, 200})
                                        addLog("monitor - Show MONITOR information", {200, 200, 200})
                                        addLog("disk - Show HDD information", {200, 200, 200})
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
                                        HDD:read("apps", function (apps)
                                            apps = json.decode(apps)
                                            addLog("Installed apps (" .. #apps .. "):", {255, 255, 0})
                                            for i, appIndex in ipairs(apps) do
                                                HDD:read("apps/" .. appIndex, function(appJson)
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
                                end)

                                while true do
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
                                    
                                    SLEEP(0.2)
                                end
                            ]]
                        }
                    }, function()
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

                -- DRE(0, MONITOR.resolution.height - 20, MONITOR.resolution.width, 20, {50, 50, 50})
                -- DRE(0, MONITOR.resolution.height - 20, 20, 20, {100, 100 ,100})

                local iconSize = 32
                local margin = 20
                local textHeight = 20
                local startX = margin
                local startY = margin + 40
                local itemsPerRow = math.floor((MONITOR.resolution.width - margin * 2) / (iconSize + margin))

                OC.mousereleased = function ()end
                HDD:read("apps", function (apps)
                    apps = json.decode(apps)

                    local __apps = {}
                    for i = 1, #apps, 1 do
                        local appIndex = apps[i]
                        HDD:read("apps/" .. appIndex, function(appJson)
                            if not appJson or appJson == "" then
                                print("[OS] Error: App not found - " .. appIndex)
                                return
                            end
                            
                            local app = json.decode(appJson)

                            if app then
                                __apps[appIndex] = app
                                local row = math.floor((i-1) / itemsPerRow)
                                local col = (i-1) % itemsPerRow
                                local x = startX + col * (iconSize + margin)
                                local y = startY + row * (iconSize + margin + textHeight)

                                LDA({150, 150, 150})
                                DRE(x, y, iconSize, iconSize, A())

                                local envApps = RAM:read(2)
                                local appKey = app.name .. ":" .. app.version
                                if envApps[appKey] then
                                    LDA({0, 255, 0})
                                    DRE(x + iconSize - 5, y + iconSize - 5, 5, 5, A())
                                end

                                LDA({0,0,0})
                                LDX("Icon")
                                DTX(x + iconSize/2 - (#X() * 3), y + iconSize/2 - 3, X(), A(), 1)

                                LDA({255, 255, 255})
                                LDX(app.name)
                                DTX(x + iconSize/2 - (#X() * 3), y + iconSize + 5, X(), A(), 1)
                            end

                            if i == #apps then
                                OC.mousereleased = function (x, y)
                                    local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
                                    local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
                                    local scale = math.min(scaleX, scaleY)
                                    x, y = x / scale, y / scale
                                    for i = 1, #apps do
                                            local row = math.floor((i-1) / itemsPerRow)
                                            local col = (i-1) % itemsPerRow
                                            local iconX = startX + col * (iconSize + margin)
                                            local iconY = startY + row * (iconSize + margin + textHeight)

                                            if x >= iconX and x <= iconX + iconSize and y >= iconY and y <= iconY + iconSize then
                                                local appIndex = apps[i]
                                                if  __apps[appIndex] then
                                                    local app = __apps[appIndex]
                                                    if app then
                                                        local envApps = RAM:read(2)
                                                        local appKey = app.name .. ":" .. app.version
                                                        if envApps[appKey] then
                                                            envApps[appKey].show()
                                                        else
                                                            OC:loadApp(appIndex)
                                                        end
                                                        return
                                                    end
                                                end
                                                break
                                            end
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
            read(1)()
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

return OC
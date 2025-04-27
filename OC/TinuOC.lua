local json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinyOS",
    is_installing = false,
    logs = {}
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
    OC.logs = {}
    local origPrint = print
    print = function (...)
        origPrint(...)
        table.insert(OC.logs,json.encode({...}))
    end
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

    -- HDD:addEventListener("write", function(hdd, address)
    --     print(string.format("[HDD] Write: addr=" .. address .. ", used=%.2fMB/%.2fMB",
    --         hdd.usedSpace/1024, hdd.effectiveCapacity))
    -- end)

    -- HDD:addEventListener("read", function(hdd, address)
    --     print(string.format("[HDD] Read: addr=" .. address))
    -- end)

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

local openFileDialog = function(callback)
    local function split(str, delimiter)
        local result = {}
        for part in str:gmatch("[^" .. delimiter .. "]+") do
            table.insert(result, part)
        end
        return result
    end
    local fileDialog = {
        selectedIndex = 1,
        files = {},
        directories = {},
        currentPath = "files",
        visible = true
    }

    local originalMouseReleased = OC.mousereleased
    local originalKeypressed = OC.keypressed

    local drawFileDialog = function()
        LDA({0, 0, 0, 150})
        DRE(0, 0, MONITOR.resolution.width, MONITOR.resolution.height, A())

        local dialogWidth = 400
        local dialogHeight = 300
        local dialogX = (MONITOR.resolution.width - dialogWidth) / 2
        local dialogY = (MONITOR.resolution.height - dialogHeight) / 2
        
        LDA({50, 50, 50})
        DRE(dialogX, dialogY, dialogWidth, dialogHeight, A())
        
        LDA({255, 255, 255})
        LDX("Select file - "..fileDialog.currentPath)
        DTX(dialogX + 10, dialogY + 10, X(), A(), 2)

        local listX = dialogX + 10
        local listY = dialogY + 40
        local itemHeight = 20
        local visibleItems = math.floor((dialogHeight - 80) / itemHeight)

        local allItems = {}
        for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
        for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end

        local startIndex = math.max(1, fileDialog.selectedIndex - math.floor(visibleItems/2))
        startIndex = math.min(startIndex, #allItems - visibleItems + 1)
        if startIndex < 1 then startIndex = 1 end
        
        local endIndex = math.min(startIndex + visibleItems - 1, #allItems)

        for i = startIndex, endIndex do
            local item = allItems[i]
            local y = listY + (i - startIndex) * itemHeight

            if i == fileDialog.selectedIndex then
                LDA({100, 100, 255})
                DRE(listX, y, dialogWidth - 20, itemHeight, A())
            end

            if item.isDir then
                LDA({255, 255, 0})
                LDX("[DIR]")
            else
                LDA({255, 255, 255})
                LDX("[FILE]")
            end
            DTX(listX + 5, y + 5, X(), A(), 1)

            LDX(item.name)
            DTX(listX + 80, y + 5, X(), A(), 1)
        end

        LDA({100, 100, 100})
        DRE(dialogX + 10, dialogY + dialogHeight - 40, 100, 30, A())
        LDA({255, 255, 255})
        LDX("Open")
        DTX(dialogX + 35, dialogY + dialogHeight - 30, X(), A(), 1)
        
        LDA({100, 100, 100})
        DRE(dialogX + 120, dialogY + dialogHeight - 40, 100, 30, A())
        LDA({255, 255, 255})
        LDX("Close")
        DTX(dialogX + 145, dialogY + dialogHeight - 30, X(), A(), 1)

        DTX(dialogWidth - 200, dialogHeight - 15, "backspace - back, return - open", {255, 255, 255}, 1)
    end

    local function updateFileList()
        FILE_SYSTEM:getDirFiles(fileDialog.currentPath, function(files, directories)
            fileDialog.files = {}
            fileDialog.directories = {}

            if not files then
                files = {}
            end
            if not directories then
                directories = {}
            end

            for path, _ in pairs(files) do
                local fullPath = fileDialog.currentPath.."/"..path
                table.insert(fileDialog.files, {
                    name = path,
                    path = fullPath,
                    isDir = false
                })
            end

            for _, path in pairs(directories) do
                local fullPath = fileDialog.currentPath.."/"..path
                table.insert(fileDialog.directories, {
                    name = path,
                    path = fullPath,
                    isDir = true
                })
            end

            table.sort(fileDialog.directories, function(a, b) return a.name < b.name end)
            table.sort(fileDialog.files, function(a, b) return a.name < b.name end)
            
            fileDialog.selectedIndex = 1
            drawFileDialog()
        end, true)
    end

    updateFileList()

    OC.mousereleased = function(x, y)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        
        local dialogWidth = 400
        local dialogHeight = 300
        local dialogX = (MONITOR.resolution.width - dialogWidth) / 2
        local dialogY = (MONITOR.resolution.height - dialogHeight) / 2
    
        if x >= dialogX + 10 and x <= dialogX + 110 and
           y >= dialogY + dialogHeight - 40 and y <= dialogY + dialogHeight - 10 then
            local allItems = {}
            for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
            for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
            
            if #allItems > 0 and fileDialog.selectedIndex >= 1 and fileDialog.selectedIndex <= #allItems then
                local selected = allItems[fileDialog.selectedIndex]
                
                if selected.isDir then
                    fileDialog.currentPath = selected.path
                    updateFileList()
                else
                    local file = FILE_SYSTEM:open(selected.path, "r", true)
                    file:read(function(data)
                        file:close()
                        
                        GPU:clear()
                        OC.mousereleased = originalMouseReleased
                        OC.keypressed = originalKeypressed
                        
                        callback({
                            path = selected.path,
                            name = selected.name,
                            data = data
                        })
                    end)
                    return nil
                end
            end
        elseif x >= dialogX + 120 and x <= dialogX + 220 and
               y >= dialogY + dialogHeight - 40 and y <= dialogY + dialogHeight - 10 then
            GPU:clear()
            OC.mousereleased = originalMouseReleased
            OC.keypressed = originalKeypressed
            callback(nil)
            return nil
        else
            local listX = dialogX + 10
            local listY = dialogY + 40
            local itemHeight = 20
            local visibleItems = math.floor((dialogHeight - 80) / itemHeight)
            
            if x >= listX and x <= listX + dialogWidth - 20 and
               y >= listY and y <= listY + visibleItems * itemHeight then
                
                local allItems = {}
                for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
                for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
                
                local startIndex = math.max(1, fileDialog.selectedIndex - math.floor(visibleItems/2))
                startIndex = math.min(startIndex, #allItems - visibleItems + 1)
                if startIndex < 1 then startIndex = 1 end
                
                local clickedIndex = startIndex + math.floor((y - listY) / itemHeight)
                
                if clickedIndex >= 1 and clickedIndex <= #allItems then
                    fileDialog.selectedIndex = clickedIndex
                end
            end
        end
        drawFileDialog()
    end
    
    OC.keypressed = function(key, scancode, isrepeat)
        local allItems = {}
        for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
        for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
        
        if key == "up" then
            fileDialog.selectedIndex = math.max(1, fileDialog.selectedIndex - 1)
        elseif key == "down" then
            fileDialog.selectedIndex = math.min(#allItems, fileDialog.selectedIndex + 1)
        elseif key == "return" then
            local selected = allItems[fileDialog.selectedIndex]
            
            if selected.isDir then
                fileDialog.currentPath = selected.path
                updateFileList()
            else
                local file = FILE_SYSTEM:open(selected.path, "r", true)
                file:read(function(data)
                    file:close()
                    
                    GPU:clear()
                    OC.mousereleased = originalMouseReleased
                    OC.keypressed = originalKeypressed
                    
                    callback({
                        path = selected.path,
                        name = selected.name,
                        data = data
                    })
                end)
                return nil
            end
        elseif key == "escape" then
            GPU:clear()
            OC.mousereleased = originalMouseReleased
            OC.keypressed = originalKeypressed
            callback(nil)
            return nil
        elseif key == "backspace" then
            local parts = {}
            for part in fileDialog.currentPath:gmatch("[^/]+") do
                table.insert(parts, part)
            end
            
            if #parts > 1 then
                table.remove(parts)
                fileDialog.currentPath = table.concat(parts, "/")
                updateFileList()
            end
        end
        drawFileDialog()
    end

    local s, co = CPU:addThread(function()
        SLEEP(0.1)
        drawFileDialog()
    end)
    table.insert(APP.threads, co)
end

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

        
        local __DRM = DRM
        local DRM = function(...)
            if APP.isVisible then
                __DRM(...)
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
                if __path[1] ~= "Dekstop" and __path[1] ~= "Documents" then
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
                if __path[1] ~= "Dekstop" and __path[1] ~= "Documents" then
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
                if __path[1] ~= "Dekstop" and __path[1] ~= "Documents" then
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
                if __path[1] ~= "Dekstop" and __path[1] ~= "Documents" then
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
        keypressed = {},
        mousepressed = {},
        mousemoved = {}
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

    local function handleMouseMoved(x, y)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        for i = 1, #__events.mousemoved do
            __events.mousemoved[i](x, y)
        end
    end

    local function handleMousePressed(x, y)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        for i = 1, #__events.mousepressed do
            __events.mousepressed[i](x, y)
        end
    end

    local function handleKeypressed(key, scancode, isrepeat)
        for i = 1, #__events.keypressed do
            __events.keypressed[i](key, scancode, isrepeat)
        end
    end

    local function addEventHandler(name, listener)
        table.insert(__events[name], listener)
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

    OC.mousereleased = handleMouseReleased
    OC.keypressed = handleKeypressed
    OC.mousepressed = handleMousePressed
    OC.mousemoved = handleMouseMoved

    self:runAppScript(app.main, app)

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
                                OC:installApp(require("OC.TinuOC.Apps.Console"), function()
                                    OC:installApp(require("OC.TinuOC.Apps.Files"), function()
                                        OC:installApp(require("OC.TinuOC.Apps.Notepad"), function()
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
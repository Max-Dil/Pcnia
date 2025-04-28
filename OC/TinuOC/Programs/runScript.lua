local function runAppScript(self, scriptName, app)
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
        local removeEvent = APP.env.removeEvent
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

return runAppScript
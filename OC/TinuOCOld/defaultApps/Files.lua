local filesApp = {
    name = "Files",
    version = "1.1",
    main = "main",
    iconText = "File",
    icon = json.decode('[[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[235,187,44],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[255,207,64],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]],[[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240],[240,240,240]]]'),
    system = true,
    scripts = {
        main = [[
local function copyDirectory(srcPath, destPath, callback)
    FILE_SYSTEM:getDirFiles(srcPath, function(files, dirs)
        FILE_SYSTEM:mkDir(destPath, function(success)
            if not success then
                callback(false, "Failed to create destination directory")
                return
            end
            
            local filesCopied = 0
            local totalFiles = 0
            local dirsCopied = 0
            local totalDirs = #dirs

            for _ in pairs(files) do totalFiles = totalFiles + 1 end
            
            if totalFiles == 0 and totalDirs == 0 then
                callback(true)
                return
            end
            
            local function checkComplete()
                if filesCopied == totalFiles and dirsCopied == totalDirs then
                    callback(true)
                end
            end


            for filename, _ in pairs(files) do
                local srcFile = FILE_SYSTEM:open(srcPath.."/"..filename, "r", true)
                local destFile = FILE_SYSTEM:open(destPath.."/"..filename, "w", true)
                
                srcFile:read(function(data)
                    destFile:write(data, function(success)
                        srcFile:close()
                        destFile:close()
                        filesCopied = filesCopied + 1
                        checkComplete()
                    end)
                end)
            end


            for _, dirname in ipairs(dirs) do
                copyDirectory(
                    srcPath.."/"..dirname,
                    destPath.."/"..dirname,
                    function(success)
                        if success then
                            dirsCopied = dirsCopied + 1
                            checkComplete()
                        else
                            callback(false, "Failed to copy directory "..dirname)
                        end
                    end
                )
            end
        end, true)
    end, true)
end

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
    visible = true,
    fileMenu = nil,
    clipboard = nil
}

local openFile = function(data)
    if data.ext == "app" then
        APP.hide(true)
        local fileApp = FILE_SYSTEM:open(data.path, "r", true)
        fileApp:read(function (appPath)
            fileApp = FILE_SYSTEM:open(appPath .. "/app.json", "r")
            fileApp:read(function(appJson)
                local app = json.decode(appJson)

                if app then
                    local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                    local envApps = RAM:read(2)

                    local appKey = app.name .. ":" .. app.version

                    if envApps[appKey] then
                        envApps[appKey].show()
                    else
                        OC:loadApp(appIndex)
                    end
                end
            end)
        end)
        return nil
    end

    if data.ext == "txt" then
        APP.hide(true)
        SLEEP(0.5)
        local fileApp = FILE_SYSTEM:open("User/AppData/app_notepad/app.json", "r")
        fileApp:read(function (appJson)
            local app = json.decode(appJson)
            
            if app then
                local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                local envApps = RAM:read(2)

                local appKey = app.name .. ":" .. app.version
                                    
                if envApps[appKey] then
                    envApps[appKey].show()

                    local APP = envApps[app.name .. ":" .. app.version]
                    local fileName = split(data.path, "/")
                    for i=1 , #fileName, 1 do
                        if fileName[i] == "files" then
                            table.remove(fileName, i)
                        else
                            break
                        end
                    end
                    fileName = table.concat(fileName, "/")
                    local file = FILE_SYSTEM:open(fileName, "r")
                    file:read(function(text)
                        APP.loadFilePath({
                            path = data.path,
                            name = data.name,
                            data = text
                        })
                    end)
                else
                    OC:loadApp(appIndex, function()
                        ::searchAPP::
                        envApps = RAM:read(2)
                        if not envApps[app.name .. ":" .. app.version] then
                            SLEEP(1)
                            goto searchAPP
                        end

                        ::searchLoadFunc::
                        local APP = envApps[app.name .. ":" .. app.version]
                        if not APP.loadFilePath then
                            SLEEP(1)
                            goto searchLoadFunc
                        end
                        local fileName = split(data.path, "/")
                        for i=1 , #fileName, 1 do
                            if fileName[i] == "files" then
                                table.remove(fileName, i)
                            else
                                break
                            end
                        end
                        fileName = table.concat(fileName, "/")
                        local file = FILE_SYSTEM:open(fileName, "r")
                        file:read(function(text)
                            APP.loadFilePath({
                                path = data.path,
                                name = data.name,
                                data = text
                            })
                        end)
                    end)
                end
            end
        end)
        return nil
    end

    if data.ext == "pix" then
        APP.hide(true)
        SLEEP(0.5)
        local fileApp = FILE_SYSTEM:open("User/AppData/app_paint/app.json", "r")
        fileApp:read(function (appJson)
            local app = json.decode(appJson)
            
            if app then
                local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                local envApps = RAM:read(2)

                local appKey = app.name .. ":" .. app.version
                                    
                if envApps[appKey] then
                    envApps[appKey].show()

                    local APP = envApps[app.name .. ":" .. app.version]
                    local fileName = split(data.path, "/")
                    for i=1 , #fileName, 1 do
                        if fileName[i] == "files" then
                            table.remove(fileName, i)
                        else
                            break
                        end
                    end
                    fileName = table.concat(fileName, "/")
                    local file = FILE_SYSTEM:open(fileName, "r")
                    file:read(function(text)
                        APP.loadFilePath({
                            path = data.path,
                            name = data.name,
                            data = text
                        })
                    end)
                else
                    OC:loadApp(appIndex, function()
                        ::searchAPP::
                        envApps = RAM:read(2)
                        if not envApps[app.name .. ":" .. app.version] then
                            SLEEP(1)
                            goto searchAPP
                        end

                        ::searchLoadFunc::
                        local APP = envApps[app.name .. ":" .. app.version]
                        if not APP.loadFilePath then
                            SLEEP(1)
                            goto searchLoadFunc
                        end
                        local fileName = split(data.path, "/")
                        for i=1 , #fileName, 1 do
                            if fileName[i] == "files" then
                                table.remove(fileName, i)
                            else
                                break
                            end
                        end
                        fileName = table.concat(fileName, "/")
                        local file = FILE_SYSTEM:open(fileName, "r")
                        file:read(function(text)
                            APP.loadFilePath({
                                path = data.path,
                                name = data.name,
                                data = text
                            })
                        end)
                    end)
                end
            end
        end)
        return nil
    end

end

local drawFileDialog = function()
    LDA({0, 0, 0, 150})
    DRE(0, 0, MONITOR.resolution.width, MONITOR.resolution.height, A())

    local dialogWidth = MONITOR.resolution.width
    local dialogHeight = MONITOR.resolution.height
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

    LDA({70, 70, 70})
    if fileDialog.clipboard then
        LDA({70, 170, 70})
    end
    DRE(dialogX + 110, dialogY + dialogHeight - 40, 100, 30, A())
    LDA({255, 255, 255})
    LDX("Paste")
    DTX(dialogX + 125, dialogY + dialogHeight - 30, X(), A(), 1)

    LDA({100, 100, 100})
    DRE(dialogX + 220, dialogY + dialogHeight - 40, 80, 30, A())
    LDA({255, 255, 255})
    LDX("New File")
    DTX(dialogX + 230, dialogY + dialogHeight - 30, X(), A(), 1)

    LDA({100, 100, 100})
    DRE(dialogX + 310, dialogY + dialogHeight - 40, 80, 30, A())
    LDA({255, 255, 255})
    LDX("New Folder")
    DTX(dialogX + 315, dialogY + dialogHeight - 30, X(), A(), 1)

    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})

    if fileDialog.fileMenu then
        DRE(fileDialog.fileMenu.x, fileDialog.fileMenu.y, 50, 100, {100, 100, 100})

        local x, y = math.ceil(fileDialog.fileMenu.x), math.ceil(fileDialog.fileMenu.y)
        DTX(x + 2, y + 2, "Delete", {255, 255, 255}, 1)

        local x, y = math.ceil(fileDialog.fileMenu.x), math.ceil(fileDialog.fileMenu.y)
        DTX(x + 2, y + 12, "Copy", {255, 255, 255}, 1)
    end
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

local function createNewFile()
    local dialogWidth = 200
    local dialogHeight = 100
    local dialogX = (MONITOR.resolution.width - dialogWidth) / 2
    local dialogY = (MONITOR.resolution.height - dialogHeight) / 2
    
    local filename = ""
    local active = true
    
    local function drawDialog()
        LDA({50, 50, 50})
        DRE(dialogX, dialogY, dialogWidth, dialogHeight, A())
        
        LDA({255, 255, 255})
        LDX("Enter filename:")
        DTX(dialogX + 10, dialogY + 10, X(), A(), 1)
        
        LDA({70, 70, 70})
        DRE(dialogX + 10, dialogY + 30, dialogWidth - 20, 20, A())
        
        LDA({255, 255, 255})
        LDX(filename)
        DTX(dialogX + 15, dialogY + 35, X(), A(), 1)
        
        LDA({100, 100, 100})
        DRE(dialogX + 10, dialogY + 70, 80, 20, A())
        LDA({255, 255, 255})
        LDX("Create")
        DTX(dialogX + 30, dialogY + 75, X(), A(), 1)
        
        LDA({100, 100, 100})
        DRE(dialogX + 110, dialogY + 70, 80, 20, A())
        LDA({255, 255, 255})
        LDX("Cancel")
        DTX(dialogX + 125, dialogY + 75, X(), A(), 1)
    end
    
    local orig = APP.__events.keypressed[1]
    removeEvent("keypressed",orig)

    local origM = APP.__events.mousereleased[1]
    removeEvent("mousereleased",origM)

    addEvent("keypressed", function(key)
        if not active then return end
        
        if key == "backspace" then
            filename = filename:sub(1, -2)
        elseif key == "return" then
            if filename ~= "" then
                local path = fileDialog.currentPath.."/"..filename
                local file = FILE_SYSTEM:open(path, "w", true)
                file:write("", function(success)
                    file:close()
                    if success then
                        table.remove(APP.__events.mousereleased, 1)
                        addEvent("mousereleased", origM)
                        table.remove(APP.__events.keypressed, 1)
                        addEvent("keypressed", orig)
                        updateFileList()
                        active = false
                    end
                end)
            end
        elseif (key:match("%g") or key == "space") and #filename < 20 then
            filename = filename .. (key == "space" and " " or key)
        end
        
        drawDialog()
    end)

    addEvent("mousereleased", function(x, y)
        if not active then return end
        
        if x >= dialogX + 10 and x <= dialogX + 90 and
           y >= dialogY + 70 and y <= dialogY + 90 then
            if filename ~= "" then
                local path = fileDialog.currentPath.."/"..filename
                local file = FILE_SYSTEM:open(path, "w", true)
                file:write("", function(success)
                    file:close()
                    if success then
                        table.remove(APP.__events.mousereleased, 1)
                        addEvent("mousereleased", origM)
                        table.remove(APP.__events.keypressed, 1)
                        addEvent("keypressed", orig)
                        updateFileList()
                        active = false
                    end
                end)
            end
        elseif x >= dialogX + 110 and x <= dialogX + 190 and
               y >= dialogY + 70 and y <= dialogY + 90 then
            table.remove(APP.__events.mousereleased, 1)
            addEvent("mousereleased", origM)
            table.remove(APP.__events.keypressed, 1)
            addEvent("keypressed", orig)
            active = false
            drawFileDialog()
        end
    end)
    
    drawDialog()
end

local function createNewFolder()
    local dialogWidth = 200
    local dialogHeight = 100
    local dialogX = (MONITOR.resolution.width - dialogWidth) / 2
    local dialogY = (MONITOR.resolution.height - dialogHeight) / 2
    
    local foldername = ""
    local active = true
    
    local function drawDialog()
        LDA({50, 50, 50})
        DRE(dialogX, dialogY, dialogWidth, dialogHeight, A())
        
        LDA({255, 255, 255})
        LDX("Enter folder name:")
        DTX(dialogX + 10, dialogY + 10, X(), A(), 1)
        
        LDA({70, 70, 70})
        DRE(dialogX + 10, dialogY + 30, dialogWidth - 20, 20, A())
        
        LDA({255, 255, 255})
        LDX(foldername)
        DTX(dialogX + 15, dialogY + 35, X(), A(), 1)
        
        LDA({100, 100, 100})
        DRE(dialogX + 10, dialogY + 70, 80, 20, A())
        LDA({255, 255, 255})
        LDX("Create")
        DTX(dialogX + 30, dialogY + 75, X(), A(), 1)
        
        LDA({100, 100, 100})
        DRE(dialogX + 110, dialogY + 70, 80, 20, A())
        LDA({255, 255, 255})
        LDX("Cancel")
        DTX(dialogX + 125, dialogY + 75, X(), A(), 1)
    end
    
    local orig = APP.__events.keypressed[1]
    removeEvent("keypressed",orig)

    local origM = APP.__events.mousereleased[1]
    removeEvent("mousereleased",origM)

    addEvent("keypressed", function(key)
        if not active then return end
        
        if key == "backspace" then
            foldername = foldername:sub(1, -2)
        elseif key == "return" then
            if foldername ~= "" then
                local path = fileDialog.currentPath.."/"..foldername
                FILE_SYSTEM:mkDir(path, function(success)
                    if success then
                        table.remove(APP.__events.keypressed, 1)
                        addEvent("keypressed", orig)
                        table.remove(APP.__events.mousereleased, 1)
                        addEvent("mousereleased", origM)
                        updateFileList()
                        active = false
                    end
                end, true)
            end
        elseif (key:match("%g") or key == "space") and #foldername < 20 then
            foldername = foldername .. (key == "space" and " " or key)
        end
        
        drawDialog()
    end)

    addEvent("mousereleased", function(x, y)
        if not active then return end
        
        if x >= dialogX + 10 and x <= dialogX + 90 and
           y >= dialogY + 70 and y <= dialogY + 90 then
            if foldername ~= "" then
                local path = fileDialog.currentPath.."/"..foldername
                FILE_SYSTEM:mkDir(path, function(success)
                    if success then
                        table.remove(APP.__events.keypressed, 1)
                        addEvent("keypressed", orig)
                        table.remove(APP.__events.mousereleased, 1)
                        addEvent("mousereleased", origM)
                        updateFileList()
                        active = false
                    end
                end, true)
            end
        elseif x >= dialogX + 110 and x <= dialogX + 190 and
               y >= dialogY + 70 and y <= dialogY + 90 then
            table.remove(APP.__events.keypressed, 1)
            addEvent("keypressed", orig)
            table.remove(APP.__events.mousereleased, 1)
            addEvent("mousereleased", origM)
            active = false
            drawFileDialog()
        end
    end)
    
    drawDialog()
end

updateFileList()
addEvent("mousereleased", function(x, y, button)
    local dialogWidth = MONITOR.resolution.width
    local dialogHeight = MONITOR.resolution.height
    local dialogX = (MONITOR.resolution.width - dialogWidth) / 2
    local dialogY = (MONITOR.resolution.height - dialogHeight) / 2

    if fileDialog.fileMenu then
        local menuX, menuY = fileDialog.fileMenu.x, fileDialog.fileMenu.y
        local menuWidth, menuHeight = 50, 100
        
        if x >= menuX and x <= menuX + menuWidth and
           y >= menuY and y <= menuY + menuHeight then
           
            if y >= menuY + 2 and y <= menuY + 12 then
                local allItems = {}
                for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
                for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
                
                if fileDialog.selectedIndex >= 1 and fileDialog.selectedIndex <= #allItems then
                    local selected = allItems[fileDialog.selectedIndex]

                    local path = split(selected.path, "/")
                    for i=1 , #path, 1 do
                        if path[i] == "files" then
                            table.remove(path, i)
                        else
                            break
                        end
                    end
                    path = table.concat(path, "/")

                    if selected.isDir then
                        FILE_SYSTEM:rmDir(path, function(success)
                            if success then
                                updateFileList()
                            end
                        end)
                    else

                        local file = FILE_SYSTEM:open(path, "w")
                        file:remove(function(success, err)
                            file.close()
                            if success then
                                updateFileList()
                            end
                        end)
                    end
                end
            elseif y >= menuY + 12 and y <= menuY + 22 then
                local allItems = {}
                for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
                for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
                
                if fileDialog.selectedIndex >= 1 and fileDialog.selectedIndex <= #allItems then
                    local selected = allItems[fileDialog.selectedIndex]
                    fileDialog.clipboard = {
                        path = selected.path,
                        isDir = selected.isDir
                    }
                end
            end
        end
        
        fileDialog.fileMenu = nil
        drawFileDialog()
        return
    end
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
                    
                    openFile({
                        path = selected.path,
                        name = selected.name,
                        data = data,
                        ext = file.fileExt
                    })
                end)
                return nil
            end
        end
    elseif x >= dialogX + 220 and x <= dialogX + 300 and
       y >= dialogY + dialogHeight - 40 and y <= dialogY + dialogHeight - 10 then
        createNewFile()
        return nil
    elseif x >= dialogX + 310 and x <= dialogX + 390 and
       y >= dialogY + dialogHeight - 40 and y <= dialogY + dialogHeight - 10 then
        createNewFolder()
        return nil
    elseif x >= dialogX + 120 and x <= dialogX + 220 and
       y >= dialogY + dialogHeight - 40 and y <= dialogY + dialogHeight - 10 then
    if fileDialog.clipboard then
        local allItems = {}
        for _, dir in ipairs(fileDialog.directories) do table.insert(allItems, dir) end
        for _, file in ipairs(fileDialog.files) do table.insert(allItems, file) end
        
        if fileDialog.clipboard.isDir then
            local newPath = fileDialog.currentPath.."/"..fileDialog.clipboard.path:match("([^/]+)$")
            copyDirectory(
                fileDialog.clipboard.path,
                newPath,
                function(success)
                    if success then
                        fileDialog.clipboard = nil
                        updateFileList()
                    else
                        print("Error copy folder")
                    end
                end
            )
        else
            local newPath = fileDialog.currentPath.."/"..fileDialog.clipboard.path:match("([^/]+)$")
            local origFile = FILE_SYSTEM:open(fileDialog.clipboard.path, "r", true)
            local newFile = FILE_SYSTEM:open(newPath, "w", true)
            
            origFile:read(function(data)
                origFile:close()
                newFile:write(data, function(success)
                    newFile:close()
                    fileDialog.clipboard = nil
                    updateFileList()
                end)
            end)
        end
    end
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
                if button == 2 then
                    fileDialog.fileMenu = {
                        x = x, y = y
                    }
                end
            end
        end
    end
    drawFileDialog()
end)

addEvent("keypressed",function(key, scancode, isrepeat)
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
            
                openFile({
                    path = selected.path,
                    name = selected.name,
                    data = data,
                    ext = file.fileExt
                })
            end)
            return nil
        end
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
end)

while true do
    SLEEP(0.05)
end
        ]]
    }
}

return filesApp
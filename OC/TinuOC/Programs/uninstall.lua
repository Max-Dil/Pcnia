local function uninstallApp(self, appName, callback)
    CPU:addThread(function ()
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
                                HDD:saveToFile("TinuOC")
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
    end)
end

return uninstallApp
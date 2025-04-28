local function installApp(self, appData, callback)
    CPU:addThread(function ()
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
    end)
end

return installApp
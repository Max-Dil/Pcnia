local function loadApp(self, appIndex, callback)
    CPU:addThread(function ()
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
    end)
end

return loadApp
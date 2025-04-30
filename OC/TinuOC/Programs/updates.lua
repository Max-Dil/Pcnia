local function updateAppsSearch(callback)
    -- System:
    local updates = {}
    local system_apps = {{"notepad", "OC.TinuOC.defaultApps.Notepad"}, {"files", "OC.TinuOC.defaultApps.Files"}, {"console", "OC.TinuOC.defaultApps.Console"},
    {"paint", "OC.TinuOC.defaultApps.Paint"}}
    for i = 1, #system_apps, 1 do
        local file = FILE_SYSTEM:open("User/AppData/app_"..system_apps[i][1].."/app.json", "r")
        file:read(function (appJson)
            local success, app = pcall(json.decode, appJson)
    
            if app then
                local newApp = require(system_apps[i][2])

                if tonumber(app.version) < tonumber(newApp.version) then
                    table.insert(updates, {
                        name = newApp.name,
                        oldVersion = app.version,
                        newVersion = newApp.version,
                        newApp = newApp,
                        oldApp = app
                    })
                end
            end

            if i == #system_apps then
                callback(updates)
            end
        end)
    end
end

return updateAppsSearch
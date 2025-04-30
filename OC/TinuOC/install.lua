local function installDefaultOS(self)
    CPU:addThread(function ()
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
                                    OC:installApp(require("OC.TinuOC.defaultApps.Console"), function()
                                        OC:installApp(require("OC.TinuOC.defaultApps.Files"), function()
                                            OC:installApp(require("OC.TinuOC.defaultApps.Notepad"), function()
                                                OC:installApp(require("OC.TinuOC.defaultApps.Paint"), function()
                                                    OC.is_installing = false
                                                    print("[OS] Default OS installed successfully")
                                                    HDD:saveToFile("TinuOC")
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
        end)
    end)
end

return installDefaultOS
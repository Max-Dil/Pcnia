local commands = {}
local oc, process

commands.init = function (config)
    oc = config.oc
    process = config.process
end

commands.help = function (shell, args, callback)
    process.addProcess("[COMMANDS] - help", function ()
        LDY{shell = shell, args = args, callback = callback}
        callback("Commands: help, clear, ver, reboot, time, processes")
        process.removeProcess("[COMMANDS] - help")
    end, function (success, error)
        if not success then
            callback("Error start command [help]:" .. error)
        end
    end)
end

commands.processes = function (shell, args, callback)
    process.addProcess("[COMMANDS] - processes", function ()
        LDY{shell = shell, args = args, callback = callback}
        if args[1] == "list" then
            process.list(function (list)
                if shell.addLineToConsole then shell.addLineToConsole("======= Processes =======") end
                for index, value in ipairs(list) do
                    if value.name ~= "[COMMANDS] - processes" then
                        if shell.addLineToConsole then shell.addLineToConsole("P: "..value.id.." name: "..value.name.." status: "..value.status) end
                    end
                end
                if shell.addLineToConsole then shell.addLineToConsole("======= End =======") end
                process.removeProcess("[COMMANDS] - processes")
            end)
        elseif args[1] == "remove" then
            local name = args[2]
            process.removeProcess(name, function (success, error)
                if success then
                    if shell.addLineToConsole then shell.addLineToConsole("Processes "..name.." success delete.") end
                else
                    if shell.addLineToConsole then shell.addLineToConsole("Error processes "..name.." delete: "..error) end
                end
            end)
        end
    end, function (success, error)
        if not success then
            callback("Error start command [processes]:" .. error)
        end
    end)
end

commands.time = function (shell, args, callback)
    process.addProcess("[COMMANDS] - time", function ()
        LDY{shell = shell, args = args, callback = callback}
        callback("OS time: "..os.time())
        process.removeProcess("[COMMANDS] - time")
    end, function (success, error)
        if not success then
            callback("Error start command [time]:" .. error)
        end
    end)
end

commands.clear = function (shell, args, callback)
    process.addProcess("[COMMANDS] - clear", function ()
        LDY{shell = shell, args = args, callback = callback}
        if Y().shell.clear then
           Y().shell.clear()
        else
           Y().callback("[ERROR] Shell does not support clearing the console.")
        end
        process.removeProcess("[COMMANDS] - clear")
    end, function (success, error)
        if not success then
            callback("Error start command [clear]:" .. error)
        end
    end)
end

commands.ver = function (shell, args, callback)
    process.addProcess("[COMMANDS] - ver", function ()
        LDY{shell = shell, args = args, callback = callback}
        Y().callback("Virtual Shell v" .. tostring(Y().shell.version))
        process.removeProcess("[COMMANDS] - ver")
    end, function (success, error)
        if not success then
            callback("Error start command [ver]:" .. error)
        end
    end)
end

commands.reboot = function (shell, args, callback)
    process.addProcess("[COMMANDS] - reboot", function ()
        LDY{shell = shell, args = args, callback = callback}

        if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] Rebooting...") end

        process.list(function (list)
            if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] Found " .. #list .. " processes to remove.") end

            local function removeNextProcess(index)
                if index > #list then
                    if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] All processes removed.") end

                    LDA(oc.devices.RAM)
                    if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] Clear ram storage: "..#A()._memory) end
                    free(0, #A()._memory)
                    SLEEP(1)

                    process.removeProcess("[COMMANDS] - reboot")
                    oc.init(oc.config)
                    return
                end

                local processToRemove = list[index]

                if processToRemove.name == "[COMMANDS] - reboot" then
                    removeNextProcess(index + 1)
                    return
                end
                
                if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] Removing process: " .. processToRemove.name) end

                process.removeProcess(processToRemove.name, function (success, err)
                    if success then
                        if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] -> Success remove: "..processToRemove.name) end
                    else
                        if shell.addLineToConsole then shell.addLineToConsole("[COMMANDS] -> Failed to remove: "..processToRemove.name..": "..tostring(err)) end
                    end
                    SLEEP(0.1)

                    removeNextProcess(index + 1)
                end)
            end

            removeNextProcess(1)
        end)

    end, function (success, error)
        if not success then
            callback("[COMMANDS] Error starting reboot process: "..error)
        end
    end)
end

return commands

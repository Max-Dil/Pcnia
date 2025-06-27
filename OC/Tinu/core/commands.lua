-- commands.lua
local commands = {}
local oc, process, fs

local function resolvePath(currentDir, targetPath)
    if not targetPath or targetPath == "" then
        return currentDir
    end

    if string.sub(targetPath, 1, 1) == "/" then
        currentDir = "/"
        targetPath = string.sub(targetPath, 2)
    end

    local currentParts = {}
    for part in string.gmatch(currentDir, "[^/]+") do
        table.insert(currentParts, part)
    end

    for part in string.gmatch(targetPath, "[^/]+") do
        if part == ".." then
            table.remove(currentParts)
        elseif part ~= "." then
            table.insert(currentParts, part)
        end
    end

    local newPath = "/" .. table.concat(currentParts, "/")
    if #currentParts > 0 and newPath ~= "/" then
    end
    
    return newPath
end

commands.init = function (config)
    oc = config.oc
    process = config.process
    fs = config.fs
end

commands.help = function (shell, args, callback)
    process.addProcess("[COMMANDS] - help", function ()
        callback("Commands: help, clear, ver, reboot, time, processes, ls, cd, mkdir, rmdir")
        process.removeProcess("[COMMANDS] - help")
    end)
end

commands.ls = function (shell, args, callback)
    process.addProcess("[COMMANDS] - ls", function()
        local currentDir = shell.getCurrentDirectory()
        local targetPath = args[1] or ""
        local pathToList = resolvePath(currentDir, targetPath)

        fs:getDirFiles(pathToList, function(files, directories)
            if not files and not directories then
                callback("ls: cannot access '" .. pathToList .. "': No such file or directory")
                process.removeProcess("[COMMANDS] - ls")
                return
            end

            callback("Contents of " .. pathToList .. ":")
            for _, dirName in ipairs(directories) do
                callback("  [DIR] " .. dirName)
            end
            for fileName, _ in pairs(files) do
                callback("  " .. fileName)
            end
            process.removeProcess("[COMMANDS] - ls")
        end, true)
    end)
end

commands.cd = function (shell, args, callback)
    process.addProcess("[COMMANDS] - cd", function()
        local targetDir = args[1]
        if not targetDir then
            shell.setCurrentDirectory("/")
            process.removeProcess("[COMMANDS] - cd")
            return
        end

        local currentDir = shell.getCurrentDirectory()
        local newPath = resolvePath(currentDir, targetDir)

        if newPath == "/" then
            shell.setCurrentDirectory("/")
            process.removeProcess("[COMMANDS] - cd")
            return
        end

        fs:isDirectory(newPath, function(isDir, err)
            if isDir then
                shell.setCurrentDirectory(newPath)
            else
                callback("cd: " .. (err or "'" .. newPath .. "': Not a directory"))
            end
            process.removeProcess("[COMMANDS] - cd")
        end, true)
    end)
end

commands.mkdir = function (shell, args, callback)
    process.addProcess("[COMMANDS] - mkdir", function()
        local dirName = args[1]
        if not dirName then
            callback("mkdir: missing operand")
            process.removeProcess("[COMMANDS] - mkdir")
            return
        end
        
        local currentDir = shell.getCurrentDirectory()
        local newDirPath = resolvePath(currentDir, dirName)
        
        fs:mkDir(newDirPath, function(success, err)
            if success then
                callback("Directory '" .. newDirPath .. "' created.")
            else
                callback("mkdir: cannot create directory '".. newDirPath .."': " .. (err or "Operation failed"))
            end
            process.removeProcess("[COMMANDS] - mkdir")
        end, true)
    end)
end

commands.rmdir = function (shell, args, callback)
    process.addProcess("[COMMANDS] - rmdir", function()
        local dirName = args[1]
        if not dirName then
            callback("rmdir: missing operand")
            process.removeProcess("[COMMANDS] - rmdir")
            return
        end

        local currentDir = shell.getCurrentDirectory()
        local dirToRemovePath = resolvePath(currentDir, dirName)

        if dirToRemovePath == "/" then
            callback("rmdir: cannot remove root directory")
            process.removeProcess("[COMMANDS] - rmdir")
            return
        end

        fs:rmDir(dirToRemovePath, function(success, err)
            if success then
                callback("Directory '" .. dirToRemovePath .. "' removed.")
            else
                callback("rmdir: failed to remove '" .. dirToRemovePath .. "': " .. (err or "Operation failed"))
            end
            process.removeProcess("[COMMANDS] - rmdir")
        end, true)
    end)
end


commands.processes = function (shell, args, callback)
    process.addProcess("[COMMANDS] - processes", function ()
        if args[1] == "list" then
            process.list(function (list)
                shell.addLineToConsole("======= Processes =======")
                for _, value in ipairs(list) do
                    if value.name ~= "[COMMANDS] - processes" then
                        shell.addLineToConsole("P: "..value.id.." name: "..value.name.." status: "..value.status)
                    end
                end
                shell.addLineToConsole("======= End =======")
                process.removeProcess("[COMMANDS] - processes")
            end)
        elseif args[1] == "remove" then
            local name = args[2]
            process.removeProcess(name, function (success, error)
                if success then
                    shell.addLineToConsole("Process "..name.." successfully deleted.")
                else
                    shell.addLineToConsole("Error deleting process "..name..": "..error)
                end
            end)
        else
            callback("Usage: processes [list|remove <name>]")
            process.removeProcess("[COMMANDS] - processes")
        end
    end)
end

commands.time = function (shell, args, callback)
    process.addProcess("[COMMANDS] - time", function ()
        callback("OS time: "..os.time())
        process.removeProcess("[COMMANDS] - time")
    end)
end

commands.clear = function (shell, args, callback)
    process.addProcess("[COMMANDS] - clear", function ()
        shell.clear()
        process.removeProcess("[COMMANDS] - clear")
    end)
end

commands.ver = function (shell, args, callback)
    process.addProcess("[COMMANDS] - ver", function ()
        -- The shell version is in the API
        callback("Virtual Shell v" .. tostring(shell.version))
        process.removeProcess("[COMMANDS] - ver")
    end)
end

commands.reboot = function (shell, args, callback)
    process.addProcess("[COMMANDS] - reboot", function ()
        callback("[SYSTEM] Rebooting...")

        process.list(function (list)
            callback("[SYSTEM] Found " .. #list .. " processes to remove.")

            local function removeNextProcess(index)
                if index > #list then
                    callback("[SYSTEM] All processes removed.")

                    LDA(oc.devices.RAM)
                    callback("[SYSTEM] Clearing RAM storage: " .. #A()._memory)
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
                
                callback("[SYSTEM] Removing process: " .. processToRemove.name)

                process.removeProcess(processToRemove.name, function (success, err)
                    if success then
                        callback("[SYSTEM] -> Success remove: "..processToRemove.name)
                    else
                        callback("[SYSTEM] -> Failed to remove: "..processToRemove.name..": "..tostring(err))
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

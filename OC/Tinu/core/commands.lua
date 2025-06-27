-- commands.lua
local commands = {
    app = {}
}
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

commands.load = function (shell, args, callback)
	process.addProcess("[COMMANDS] - load", function()
		local app = read(9)
		if not app then
			callback("load: Application module not found.")
			process.removeProcess("[COMMANDS] - load")
			return
		end

		local path = args[1]
		if not path then
			callback("load: missing file operand. Usage: load <path>")
			process.removeProcess("[COMMANDS] - load")
			return
		end
		
		local fullPath = resolvePath(shell.getCurrentDirectory(), path)
		
		app.load(fullPath, function(success, message)
			callback(message)
			process.removeProcess("[COMMANDS] - load")
		end)
	end)
end

commands.run = function (shell, args, callback)
	process.addProcess("[COMMANDS] - run", function()
		local app = read(9)
		if not app then
			callback("run: Application module not found.")
			process.removeProcess("[COMMANDS] - run")
			return
		end

		local path = args[1]
		if not path then
			callback("run: missing file operand. Usage: run <path>")
			process.removeProcess("[COMMANDS] - run")
			return
		end
		
		local fullPath = resolvePath(shell.getCurrentDirectory(), path)

		app.run(fullPath, function(success, message)
			if message then
				callback(message)
			end
			process.removeProcess("[COMMANDS] - run")
		end)
	end)
end

commands.help = function (shell, args, callback)
	process.addProcess("[COMMANDS] - help", function ()
		callback("Commands: help, clear, ver")
		callback("OS: reboot, time, processes")
		callback("Folders: ls, cd, mkdir, rmdir")
		callback("Files: touch, rm, cp, mv")
		callback("Apps: load, run")
		process.removeProcess("[COMMANDS] - help")
	end)
end

commands.touch = function (shell, args, callback)
	process.addProcess("[COMMANDS] - touch", function()
		local fileName = args[1]
		if not fileName then
			callback("touch: missing file operand")
			process.removeProcess("[COMMANDS] - touch")
			return
		end

		local filePath = resolvePath(shell.getCurrentDirectory(), fileName)
		local file = fs:open(filePath, "w", true)

        print(filePath)
		file:write("", function(success, err)
			if success then
				callback("File '" .. filePath .. "' created.")
			else
				callback("touch: cannot create file '" .. filePath .. "': " .. (err or "Operation failed"))
			end
			process.removeProcess("[COMMANDS] - touch")
		end)
	end)
end

commands.rm = function (shell, args, callback)
	process.addProcess("[COMMANDS] - rm", function()
		local fileName = args[1]
		if not fileName then
			callback("rm: missing operand")
			process.removeProcess("[COMMANDS] - rm")
			return
		end

		local filePath = resolvePath(shell.getCurrentDirectory(), fileName)
		local file = fs:open(filePath, "w", true) -- режим не важен для удаления

		file:remove(function(success, err)
			if success then
				callback("File '" .. filePath .. "' removed.")
			else
				callback("rm: cannot remove file '" .. filePath .. "': " .. (err or "File not found or permission denied"))
			end
			process.removeProcess("[COMMANDS] - rm")
		end)
	end)
end

commands.cp = function (shell, args, callback)
	process.addProcess("[COMMANDS] - cp", function()
		local sourceName = args[1]
		local destName = args[2]

		if not sourceName or not destName then
			callback("cp: missing file operand. Usage: cp <source> <destination>")
			process.removeProcess("[COMMANDS] - cp")
			return
		end

		local sourcePath = resolvePath(shell.getCurrentDirectory(), sourceName)
		local destPath = resolvePath(shell.getCurrentDirectory(), destName)
		
		local sourceFile = fs:open(sourcePath, "r", true)
		sourceFile:read(function(content, readErr)
			if readErr then
				callback("cp: cannot read source file '"..sourcePath.."': "..readErr)
				process.removeProcess("[COMMANDS] - cp")
				return
			end
			
			local destFile = fs:open(destPath, "w", true)
			destFile:write(content, function(writeSuccess, writeErr)
				if writeSuccess then
					callback("File copied from '"..sourcePath.."' to '"..destPath.."'")
				else
					callback("cp: cannot write to destination file '"..destPath.."': "..writeErr)
				end
				process.removeProcess("[COMMANDS] - cp")
			end)
		end)
	end)
end

commands.mv = function (shell, args, callback)
	process.addProcess("[COMMANDS] - mv", function()
		local sourceName = args[1]
		local destName = args[2]

		if not sourceName or not destName then
			callback("mv: missing file operand. Usage: mv <source> <destination>")
			process.removeProcess("[COMMANDS] - mv")
			return
		end

		local sourcePath = resolvePath(shell.getCurrentDirectory(), sourceName)
		local destPath = resolvePath(shell.getCurrentDirectory(), destName)

		local sourceFile = fs:open(sourcePath, "r", true)
		sourceFile:read(function(content, readErr)
			if readErr then
				callback("mv: cannot read source file '"..sourcePath.."': "..readErr)
				process.removeProcess("[COMMANDS] - mv")
				return
			end
			
			local destFile = fs:open(destPath, "w", true)
			destFile:write(content, function(writeSuccess, writeErr)
				if not writeSuccess then
					callback("mv: cannot write to destination file '"..destPath.."': "..writeErr)
					process.removeProcess("[COMMANDS] - mv")
					return
				end

				local originalFile = fs:open(sourcePath, "w", true)
				originalFile:remove(function(removeSuccess, removeErr)
					if removeSuccess then
						callback("File moved from '"..sourcePath.."' to '"..destPath.."'")
					else
						callback("mv: failed to remove original file '"..sourcePath.."' after copying: "..removeErr)
					end
					process.removeProcess("[COMMANDS] - mv")
				end)
			end)
		end)
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
                callback("======= Processes =======")
                for _, value in ipairs(list) do
                    if value.name ~= "[COMMANDS] - processes" then
                        callback("P: "..value.id.." name: "..value.name.." status: "..value.status)
                    end
                end
                callback("======= End =======")
                process.removeProcess("[COMMANDS] - processes")
            end)
        elseif args[1] == "remove" then
            local name = args[2]
            process.removeProcess(name, function (success, error)
                if success then
                    callback("Process "..name.." successfully deleted.")
                else
                    callback("Error deleting process "..name..": "..error)
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
                    coroutine.yield()
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

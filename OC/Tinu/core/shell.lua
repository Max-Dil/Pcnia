-- shell.lua

local shell = {
    version = 1.3,
    isVisible = true
}

shell.run = function (process)
    process.addProcess("shell.lua", function ()

        --[[
            Initializes the core systems by loading pointers from memory.
            A -> RAM System Control (for memory allocation)
            X -> Event System (for keyboard/mouse events)
            Y -> Device Information (monitors, etc.)
        --]]
        LDA(read(0))
        LDX(read(5))
        LDY(read(1))
        
        local fs = read(4)
        if not fs then
            error("FileSystem not found at address 4")
        end
        local commands = read(8)

        ----------------------------------------------------------------------
        -- Memory Allocation & Constants
        ----------------------------------------------------------------------
        local function alloc(count)
            local addr = A().TEMP()
            if count then
                for i = addr+1, addr + count, 1 do
                    A().TEMP()
                end
            end
            return addr
        end

        local monitorWidthAddr = alloc()
        local monitorHeightAddr = alloc()
        write(monitorWidthAddr, Y().devices.MONITOR.resolution.width)
        write(monitorHeightAddr, Y().devices.MONITOR.resolution.height)

        local FONT_SCALE = 1
        local FONT_HEIGHT = 7 * FONT_SCALE
        local FONT_WIDTH = 6 * FONT_SCALE
        local textColorAddr = alloc()
        write(textColorAddr, {0.9 * 255, 0.9 * 255, 0.9 * 255})
        local promptColorAddr = alloc()
        write(promptColorAddr, {0.6 * 255, 255, 0.6 * 255})

        local inputBufferAddr = alloc()
        write(inputBufferAddr, "")

        local currentDirectoryAddr = alloc()
        write(currentDirectoryAddr, "/")

        local usableHeight = read(monitorHeightAddr) - 5 - FONT_HEIGHT - 5
        local CONSOLE_MAX_LINES = math.floor(usableHeight / (8 * FONT_SCALE))
        if CONSOLE_MAX_LINES < 10 then CONSOLE_MAX_LINES = 10 end
        local consoleBufferAddr = alloc(CONSOLE_MAX_LINES)
        local consoleStartAddr = alloc()
        local consoleCountAddr = alloc()
        write(consoleStartAddr, 0)
        write(consoleCountAddr, 0)

        local cursorBlinkTimeAddr = alloc()
        local isCursorVisibleAddr = alloc()
        write(cursorBlinkTimeAddr, 0)
        write(isCursorVisibleAddr, TRUE)

        ----------------------------------------------------------------------
        -- Console Helper Functions (Operating on RAM)
        ----------------------------------------------------------------------
        local function addLineToConsole(text)
            local start = tonumber(read(consoleStartAddr)) or 0
            local count = tonumber(read(consoleCountAddr)) or 0
        
            local index = (start + count) % CONSOLE_MAX_LINES
            write(consoleBufferAddr + index, text)
        
            if count < CONSOLE_MAX_LINES then
                write(consoleCountAddr, count + 1)
            else
                write(consoleStartAddr, (start + 1) % CONSOLE_MAX_LINES)
            end
            print(text)
        end

        local function clearConsole()
            write(consoleStartAddr, 0)
            write(consoleCountAddr, 0)
            A().FREE(consoleBufferAddr+1, CONSOLE_MAX_LINES)
        end
        
        local shell_api = alloc()
        write(shell_api, {
            version = shell.version,
            clear = clearConsole,
            getCurrentDirectory = function() return read(currentDirectoryAddr) end,
            setCurrentDirectory = function(path) write(currentDirectoryAddr, path) end
        })

        ----------------------------------------------------------------------
        -- Event Handling
        ----------------------------------------------------------------------
        local start_events = function ()
        X().mk_event("keypressed", function (e)
            if shell.isVisible then
                local currentInput = read(inputBufferAddr)

                if e.key == "backspace" then
                    if #currentInput > 0 then
                        write(inputBufferAddr, string.sub(currentInput, 1, -2))
                    end
                elseif e.key == "return" then
                    addLineToConsole(read(currentDirectoryAddr) .. "> " .. currentInput)
                    
                    if #currentInput > 0 then
                        local parts = alloc()
                        write(parts, {})
                        for part in string.gmatch(currentInput, "[^%s]+") do
                            table.insert(read(parts), part)
                        end
                        local cmd = alloc()
                        write(cmd, read(parts)[1])
                        local args = alloc()
                        write(args, {})
                        if #read(parts) > 1 then
                            for i = 2, #read(parts) do
                                table.insert(read(args), read(parts)[i])
                            end
                        end
                        A().FREE(parts)
                    
                        if commands[read(cmd)] and read(cmd) ~= "init" then
                            commands[read(cmd)](read(shell_api), read(args), addLineToConsole)
                        else
                            local appName, appCmd = read(cmd), read(args)[1]
                            local newArgs = {}
                            for i = 2, #read(args), 1 do
                                newArgs[i-1] = read(args)[i]
                            end
                            if appName and appCmd and read(8).app[appName] and read(8).app[appName][appCmd] then
                                read(8).app[appName][appCmd](read(shell_api), newArgs, addLineToConsole)
                            else
                                addLineToConsole("Unknown command: '" .. read(cmd) .. "'")
                            end
                        end
                        A().FREE(args)
                        A().FREE(cmd)
                    end
                
                    write(inputBufferAddr, "")
                elseif e.key == "space" then
                    if #currentInput < 80 then
                        write(inputBufferAddr, currentInput .. " ")
                    end
                elseif e.key and #e.key == 1 then
                    if #currentInput < 80 then
                        write(inputBufferAddr, currentInput .. e.key)
                    end
                end
            end
        end)
        end

        ----------------------------------------------------------------------
        -- Main Process Loop (Render Loop)
        ----------------------------------------------------------------------
        addLineToConsole("Virtual Shell v" .. shell.version .. ". Type 'help' for commands.")

        local speed = 0.035 -- +-30 fps
        if Y().devices.model == "Zero1" then
            speed = 0.5 -- 2 fps
        elseif Y().devices.model == "Ore" or Y().devices.model == "Zero2" or Y().devices.model == "Zero5000" then
            speed = 0.05 -- 20 fps
        end
        -- if Y().devices.model == "Zero5000 PRO MAX" then
        --     speed = 0.01 -- 90fps
        -- end
        coroutine.yield()

        local function loadAutoloadApps(callback)
            read(1).__shell_autoloads_app_premission = true
            local fs = read(4)
            local app = read(9)
            local autoloadPath = "/Tinu/autoload.json"

            fs:open(autoloadPath, "r", true):read(function(data)
                if not data or data == "" then
                    callback()
                    return
                end

                local success, autoloadList = pcall(json.decode, data)
                if not success then
                    addLineToConsole("Error loading autoload list: "..tostring(autoloadList))
                    callback()
                    return
                end

                local loadedCount = 0
                local totalToLoad = #autoloadList

                if totalToLoad == 0 then
                    callback()
                    return
                end

                addLineToConsole("Loading autoload applications...")

                local function checkDone()
                    loadedCount = loadedCount + 1
                    if loadedCount >= totalToLoad then
                        callback()
                    end
                end

                for _, appPath in ipairs(autoloadList) do
                    app.run(appPath, function(success, error)
                        if not success then
                            addLineToConsole("Error autoloading "..appPath..": "..tostring(error))
                        else
                            addLineToConsole("Autoloaded: "..appPath)
                        end
                        checkDone()
                    end)
                end
            end)
        end

        loadAutoloadApps(function()
        read(1).__shell_autoloads_app_premission = false
        start_events()
        coroutine.yield()
        end)
        while TRUE do
            SLEEP(speed)
            if shell.isVisible then
                Y().devices.GPU:clear()

                local fullRenderText = ""
                local start = read(consoleStartAddr)
                local count = read(consoleCountAddr)
                for i = 0, count - 1 do
                    local memoryIndex = (start + i) % CONSOLE_MAX_LINES
                    local lineText = read(consoleBufferAddr + memoryIndex)
                    if lineText then
                        fullRenderText = fullRenderText .. lineText .. "\n"
                    end
                end
                local currentDir = read(currentDirectoryAddr)
                local prompt = currentDir .. "> "
                local currentInput = read(inputBufferAddr)
			    fullRenderText = fullRenderText .. prompt .. currentInput

			    DTX(5, 5, fullRenderText, read(textColorAddr), FONT_SCALE)

                if (love.timer.getTime() - read(cursorBlinkTimeAddr)) > 0.5 then
                    write(cursorBlinkTimeAddr, love.timer.getTime())
                    write(isCursorVisibleAddr, not read(isCursorVisibleAddr))
                end

                if read(isCursorVisibleAddr) then
                    local cursorX = 5 + (#(prompt .. currentInput) * FONT_WIDTH)
                    local cursorY = 5 + (read(consoleCountAddr) * (8 * FONT_SCALE))

                    if cursorY + FONT_HEIGHT <= read(monitorHeightAddr) then
                        DRE(cursorX, cursorY, FONT_WIDTH, FONT_HEIGHT, read(textColorAddr))
                    end
                end
            end
            coroutine.yield()
        end
    end, function (success, error)
        if not success then
            print("[SHELL] Critical error running shell: "..tostring(error))
        end
    end)
end

return shell

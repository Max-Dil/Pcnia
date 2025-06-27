local commands = require("OC.Tinu.core.commands")

local shell = {
    version = 1.2,
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
        commands.init({oc = Y(), process = process})

        ----------------------------------------------------------------------
        -- Memory Allocation & Constants
        ----------------------------------------------------------------------
        local function alloc(count)
            local addr = A().TEMP()
            write(addr, 0)
            if count then
                for i = 1, count, 1 do
                    write(addr+i, 0)
                end
            end
            return addr
        end

        local monitorWidthAddr = alloc()
        local monitorHeightAddr = alloc()
        write(monitorWidthAddr, Y().devices.MONITOR.resolution.width)
        write(monitorHeightAddr, Y().devices.MONITOR.resolution.height)

        local FONT_SCALE = 1
        local FONT_HEIGHT = 9 * FONT_SCALE
        local FONT_WIDTH = 6 * FONT_SCALE
        local textColorAddr = alloc()
        write(textColorAddr, {0.9 * 255, 0.9 * 255, 0.9 * 255})
        local promptColorAddr = alloc()
        write(promptColorAddr, {0.6 * 255, 255, 0.6 * 255})

        local inputBufferAddr = alloc()
        write(inputBufferAddr, "")

        local usableHeight = read(monitorHeightAddr) - 5 - FONT_HEIGHT - 5
        local CONSOLE_MAX_LINES = math.floor(usableHeight / FONT_HEIGHT)
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
            free(consoleBufferAddr+1, CONSOLE_MAX_LINES)
        end
        
        local shell_api = alloc()
        write(shell_api, {
            version = shell.version,
            clear = clearConsole,
            addLineToConsole = addLineToConsole
        })

        ----------------------------------------------------------------------
        -- Event Handling
        ----------------------------------------------------------------------
        X().mk_event("keypressed", function (e)
            local currentInput = read(inputBufferAddr)

            if e.key == "backspace" then
                if #currentInput > 0 then
                    write(inputBufferAddr, string.sub(currentInput, 1, -2))
                end
            elseif e.key == "return" then
                addLineToConsole("> " .. currentInput)
                
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
                    free(parts)

                    if commands[read(cmd)] and read(cmd) ~= "init" then
                        commands[read(cmd)](read(shell_api), read(args), addLineToConsole)
                    else
                        addLineToConsole("Unknown command: '" .. read(cmd) .. "'")
                    end
                    free(args)
                    free(cmd)
                end

                write(inputBufferAddr, "")
            elseif e.key == "space" then
                if #currentInput < 80 then
                    write(inputBufferAddr, currentInput .. " ")
                end
            elseif e.key and #e.key > 0 then
                if #currentInput < 80 then
                    write(inputBufferAddr, currentInput .. e.key)
                end
            end
        end)

        ----------------------------------------------------------------------
        -- Main Process Loop (Render Loop)
        ----------------------------------------------------------------------
        addLineToConsole("Virtual Shell v" .. shell.version .. ". Type 'help' for commands.")

        local speed = 0.05 -- 20 фпс
        if Y().devices.model == "Zero1" then
            speed = 1 -- 1 фпс
        elseif Y().devices.model == "Ore" or Y().devices.model == "Zero2" or Y().devices.model == "Zero5000" then
            speed = 0.1 -- 10 фпс
        end
        coroutine.yield()
        while TRUE do
            SLEEP(speed)
            Y().devices.GPU:clear()
            local start = read(consoleStartAddr)
            local count = read(consoleCountAddr)
            for i = 0, count - 1 do
                local memoryIndex = (start + i) % CONSOLE_MAX_LINES
                local lineText = read(consoleBufferAddr + memoryIndex)
                if lineText then
                    DTX(5, 5 + i * FONT_HEIGHT, lineText, read(textColorAddr), FONT_SCALE)
                end
            end

            local prompt = "> "
            local currentInput = read(inputBufferAddr)
            local promptY = 5 + count * FONT_HEIGHT
            DTX(5, promptY, prompt .. currentInput, read(promptColorAddr), FONT_SCALE)

            if (love.timer.getTime() - read(cursorBlinkTimeAddr)) > 0.5 then
                write(cursorBlinkTimeAddr, love.timer.getTime())
                write(isCursorVisibleAddr, not read(isCursorVisibleAddr))
            end

            if read(isCursorVisibleAddr) then
                local cursorX = 5 + (#(prompt .. currentInput) * FONT_WIDTH)
                DRE(cursorX, promptY, FONT_WIDTH, FONT_HEIGHT, read(textColorAddr))
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

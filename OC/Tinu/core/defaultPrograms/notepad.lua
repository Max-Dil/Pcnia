local notepad = {
    name = "notepad",
    version = "1.1",
    title = "The official text editor from Tinu Corporation",
    code =
[==[
local function split(str, delimiter)
    local result = {}
    if not str then return result end
    for part in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

local is_open = ALLOC()
WRITE(is_open, false)

local function startEdit(path, callback)
    processes.addProcess("[NOTEPAD] - file edit path - "..path, function()
        read(5).rm_event("keypressed", CLOSE_EVENT)

        local READ, WRITE = read, write
        TERMINAL_ISVISIBLE(false)

        local FONT_SCALE = 1
        local FONT_HEIGHT = 7 * FONT_SCALE
        local FONT_WIDTH = 6 * FONT_SCALE

        local width, height = RESOLUTION()

        local topBarText = "F5 - save, F1 - exit, Arrows - navigate"

        local lines_addr = ALLOC()
        local isLOAd_addr = ALLOC()
        local isType_addr = ALLOC()
        local cursorX_addr = ALLOC()
        local cursorY_addr = ALLOC()
        local scrollX_addr = ALLOC()
        local scrollY_addr = ALLOC()
        local maxVisibleLines_addr = ALLOC()
        local maxVisibleChars_addr = ALLOC()
        local modified_addr = ALLOC()

        WRITE(lines_addr, {})
        WRITE(isLOAd_addr, true)
        WRITE(isType_addr, "txt")
        WRITE(cursorX_addr, 1)
        WRITE(cursorY_addr, 1)
        WRITE(scrollX_addr, 0)
        WRITE(scrollY_addr, 0)
        WRITE(maxVisibleLines_addr, math.floor((height - 20 - FONT_HEIGHT) / FONT_HEIGHT))
        WRITE(maxVisibleChars_addr, math.floor((width - 10) / FONT_WIDTH))
        WRITE(modified_addr, false)

        local file = read(4):open(path, "r", true)
        if file.fileExt == "json" then
            WRITE(isType_addr, "json")
        end
        
        file:read(function(value, error)
            if READ(isType_addr) == "json" then
                local success, parsed = pcall(read(2).decode, value or "")
                if success and parsed then
                    value = read(2).encode(parsed, {
                        pretty = true,
                        indent = "  ",
                        align_keys = true,
                        sort_keys = true
                    })
                end
            end
            local split_lines = split(value or "", "\n")
            WRITE(lines_addr, split_lines)
            WRITE(isLOAd_addr, false)
        end)
        
        while READ(isLOAd_addr) do
            coroutine.yield()
        end

        local function clamp(value, min, max)
            return math.max(min, math.min(max, value))
        end

        local function updateCursor()
            local cursorY = clamp(READ(cursorY_addr), 1, #READ(lines_addr))
            local cursorX = clamp(READ(cursorX_addr), 1, #READ(lines_addr)[cursorY] + 1)
            WRITE(cursorY_addr, cursorY)
            WRITE(cursorX_addr, cursorX)
            
            if cursorY < READ(scrollY_addr) + 1 then
                WRITE(scrollY_addr, cursorY - 1)
            elseif cursorY > READ(scrollY_addr) + READ(maxVisibleLines_addr) then
                WRITE(scrollY_addr, cursorY - READ(maxVisibleLines_addr))
            end
            
            if cursorX < READ(scrollX_addr) + 1 then
                WRITE(scrollX_addr, cursorX - 1)
            elseif cursorX > READ(scrollX_addr) + READ(maxVisibleChars_addr) then
                WRITE(scrollX_addr, cursorX - READ(maxVisibleChars_addr))
            end
            
            WRITE(scrollY_addr, clamp(READ(scrollY_addr), 0, math.max(0, #READ(lines_addr) - READ(maxVisibleLines_addr))))
            WRITE(scrollX_addr, clamp(READ(scrollX_addr), 0, math.max(0, #READ(lines_addr)[cursorY] - READ(maxVisibleChars_addr) + 10)))
        end

        local keypressed
        keypressed = function(e)
            if e.key == "f1" or e.key == "escape" then
                if READ(modified_addr) then
                    -- TODO: Add confirmation dialog for unsaved changes
                end
                read(3).removeProcess("[NOTEPAD] - file edit path - "..path, function()
                    TERMINAL_ISVISIBLE(true)
                    REMOVE_EVENT("keypressed", keypressed)
                    RAM.FREE(lines_addr, 1)
                    RAM.FREE(isLOAd_addr, 1)
                    RAM.FREE(isType_addr, 1)
                    RAM.FREE(cursorX_addr, 1)
                    RAM.FREE(cursorY_addr, 1)
                    RAM.FREE(scrollX_addr, 1)
                    RAM.FREE(scrollY_addr, 1)
                    RAM.FREE(maxVisibleLines_addr, 1)
                    RAM.FREE(maxVisibleChars_addr, 1)
                    RAM.FREE(modified_addr, 1)
                    write(is_open, false)
                    coroutine.yield()
                end)
            elseif e.key == "f5" then
                local content = table.concat(READ(lines_addr), "\n")

                if READ(isType_addr) == "json" then
                    local success, parsed = pcall(read(2).decode, content)
                    if success and parsed then
                        content = read(2).encode(parsed)
                    end
                end
                
                read(4):open(path, "w", true):write(content, function(success, err)
                    if success then
                        WRITE(modified_addr, false)
                    else
                        -- TODO: Show error message
                    end
                end)
            elseif e.key == "up" then
                WRITE(cursorY_addr, READ(cursorY_addr) - 1)
                updateCursor()
            elseif e.key == "down" then
                WRITE(cursorY_addr, READ(cursorY_addr) + 1)
                updateCursor()
            elseif e.key == "left" then
                WRITE(cursorX_addr, READ(cursorX_addr) - 1)
                updateCursor()
            elseif e.key == "right" then
                WRITE(cursorX_addr, READ(cursorX_addr) + 1)
                updateCursor()
            elseif e.key == "home" then
                WRITE(cursorX_addr, 1)
                updateCursor()
            elseif e.key == "end" then
                WRITE(cursorX_addr, #READ(lines_addr)[READ(cursorY_addr)] + 1)
                updateCursor()
            elseif e.key == "pageup" then
                WRITE(cursorY_addr, READ(cursorY_addr) - READ(maxVisibleLines_addr))
                updateCursor()
            elseif e.key == "pagedown" then
                WRITE(cursorY_addr, READ(cursorY_addr) + READ(maxVisibleLines_addr))
                updateCursor()
            elseif e.key == "backspace" then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                
                if cursorX > 1 then
                    local line = lines[cursorY]
                    lines[cursorY] = line:sub(1, cursorX-2) .. line:sub(cursorX)
                    WRITE(cursorX_addr, cursorX - 1)
                    WRITE(modified_addr, true)
                elseif cursorY > 1 then
                    local prevLineLength = #lines[cursorY-1]
                    lines[cursorY-1] = lines[cursorY-1] .. lines[cursorY]
                    table.remove(lines, cursorY)
                    WRITE(cursorY_addr, cursorY - 1)
                    WRITE(cursorX_addr, prevLineLength + 1)
                    WRITE(modified_addr, true)
                end
                WRITE(lines_addr, lines)
                updateCursor()
            elseif e.key == "delete" then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                local line = lines[cursorY]
                
                if cursorX <= #line then
                    lines[cursorY] = line:sub(1, cursorX-1) .. line:sub(cursorX+1)
                    WRITE(modified_addr, true)
                elseif cursorY < #lines then
                    lines[cursorY] = line .. lines[cursorY+1]
                    table.remove(lines, cursorY+1)
                    WRITE(modified_addr, true)
                end
                WRITE(lines_addr, lines)
                updateCursor()
            elseif e.key == "return" then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                local line = lines[cursorY]
                local newLine = line:sub(cursorX)
                lines[cursorY] = line:sub(1, cursorX-1)
                table.insert(lines, cursorY+1, newLine)
                WRITE(cursorY_addr, cursorY + 1)
                WRITE(cursorX_addr, 1)
                WRITE(modified_addr, true)
                WRITE(lines_addr, lines)
                updateCursor()
            elseif e.key == "space" then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. " " .. line:sub(cursorX)
                WRITE(cursorX_addr, cursorX + 1)
                WRITE(modified_addr, true)
                WRITE(lines_addr, lines)
                updateCursor()
            elseif e.key == "tab" then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. "  " .. line:sub(cursorX)
                WRITE(cursorX_addr, cursorX + 1)
                WRITE(modified_addr, true)
                WRITE(lines_addr, lines)
                updateCursor()
            elseif e.key and #e.key == 1 then
                local lines = READ(lines_addr)
                local cursorY = READ(cursorY_addr)
                local cursorX = READ(cursorX_addr)
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. e.key .. line:sub(cursorX)
                WRITE(cursorX_addr, cursorX + 1)
                WRITE(modified_addr, true)
                WRITE(lines_addr, lines)
                updateCursor()
            end
        end
        ADD_EVENT("keypressed", keypressed)

        write(is_open, true)
        while read(is_open) do
            coroutine.yield()
            CLEAR()
            
            ----- top bar ----
            DTX(5, 5, "File: "..path..(READ(modified_addr) and " *" or ""), {255, 255, 255}, FONT_SCALE)
            DTX(width - 5 - (#topBarText * FONT_WIDTH), 5, topBarText, {255, 255, 255}, FONT_SCALE)
            DLN(0, 9 + FONT_HEIGHT, width, 9 + FONT_HEIGHT, {0, 255, 0})
            ------------------

            ---- lines -------
            local lines = READ(lines_addr)
            local startLine = READ(scrollY_addr) + 1
            local endLine = math.min(startLine + READ(maxVisibleLines_addr) - 1, #lines)
            
            for i = startLine, endLine do
                local line = lines[i]
                local visibleText = line:sub(READ(scrollX_addr) + 1, READ(scrollX_addr) + READ(maxVisibleChars_addr))
                DTX(5, 12 + FONT_HEIGHT + (i - startLine) * FONT_HEIGHT, visibleText, {255, 255, 255}, FONT_SCALE)

                if i == READ(cursorY_addr) then
                    local cursorPosX = READ(cursorX_addr) - READ(scrollX_addr)
                    if cursorPosX >= 1 and cursorPosX <= READ(maxVisibleChars_addr) + 1 then
                        local cursorScreenX = 5 + (cursorPosX - 1) * FONT_WIDTH
                        local cursorScreenY = 12 + FONT_HEIGHT + (i - startLine) * FONT_HEIGHT
                        DRE(cursorScreenX, cursorScreenY, FONT_WIDTH-2, FONT_HEIGHT, {255, 255, 255})
                    end
                end
            end
            
            if READ(scrollY_addr) > 0 then
                DTX(width - 15, 15, "↑", {200, 200, 200}, FONT_SCALE)
            end
            if READ(scrollY_addr) < #lines - READ(maxVisibleLines_addr) then
                DTX(width - 15, height - 15, "↓", {200, 200, 200}, FONT_SCALE)
            end
            if READ(scrollX_addr) > 0 then
                DTX(5, height - 15, "←", {200, 200, 200}, FONT_SCALE)
            end
            if READ(scrollX_addr) < #lines[READ(cursorY_addr)] - READ(maxVisibleChars_addr) then
                DTX(width - 15, height - 15, "→", {200, 200, 200}, FONT_SCALE)
            end
            ------------------
            SLEEP(0.05)
        end
    end, function(success, error)
        if not success then
            callback(error)
        end
    end)
end

ADD_COMMAND("edit", function(shell, args, callback)
    if #args < 1 then
        callback("Usage: edit <filename>")
        return
    end
    
    local currentDir = shell.getCurrentDirectory()
    local fullPath = RESOLVE_PATH(currentDir, args[1])

    print(fullPath)
    
    fs:open(fullPath, "r", true):read(function(value, error)
        if error and not error:find("No such file") then
            callback(error)
            return
        end
        startEdit(fullPath, callback)
    end)
end)
]==],
    modules = {"lua5.1","fs","processes"},
}

local function install(process, listener)
    process.addProcess("[SYSTEM] Install - notepad", function ()
        local fs = read(4)

        fs:open("/Tinu/programs/notepad.json", "w", true):write(read(2).encode(notepad), function (success, error)
            if not success then
                listener(NIL, error)
                process.removeProcess("[SYSTEM] Install - notepad")
                return
            end

            read(1).__shell_autoloads_app_premission = true

            read(8).autoload({getCurrentDirectory = function ()
                return "/Tinu/programs"
            end}, {"add","notepad.json"}, function (text)
                listener(TRUE, text)
                read(1).__shell_autoloads_app_premission = false
                process.removeProcess("[SYSTEM] Install - notepad")
            end)
        end)
    end, function (success, error)
        if not success then
            listener(NIL, error)
            process.removeProcess("[SYSTEM] Install - notepad")
        end
    end)
end

return install
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
        TERMINAL_ISVISIBLE(false)

        local FONT_SCALE = 1
        local FONT_HEIGHT = 7 * FONT_SCALE
        local FONT_WIDTH = 6 * FONT_SCALE

        local width, height = RESOLUTION()

        local topBarText = "F5 - save, F1 - exit, Arrows - navigate"

        local lines = {}
        local isLOAd = TRUE
        local isType = "txt"

        local file = read(4):open(path, "r", true)
        if file.fileExt == "json" then
            isType = "json"
        end
        
        file:read(function(value, error)
            if isType == "json" then
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
            lines = split(value or "", "\n")
            isLOAd = false
        end)
        while isLOAd do
            coroutine.yield()
        end

        local cursorX = 1
        local cursorY = 1
        local scrollX = 0
        local scrollY = 0
        local maxVisibleLines = math.floor((height - 20 - FONT_HEIGHT) / FONT_HEIGHT)
        local maxVisibleChars = math.floor((width - 10) / FONT_WIDTH)
        local modified = false

        local function clamp(value, min, max)
            return math.max(min, math.min(max, value))
        end

        local function updateCursor()
            cursorY = clamp(cursorY, 1, #lines)
            cursorX = clamp(cursorX, 1, #lines[cursorY] + 1)
            
            if cursorY < scrollY + 1 then
                scrollY = cursorY - 1
            elseif cursorY > scrollY + maxVisibleLines then
                scrollY = cursorY - maxVisibleLines
            end
            
            if cursorX < scrollX + 1 then
                scrollX = cursorX - 1
            elseif cursorX > scrollX + maxVisibleChars then
                scrollX = cursorX - maxVisibleChars
            end
            
            scrollY = clamp(scrollY, 0, math.max(0, #lines - maxVisibleLines))
            scrollX = clamp(scrollX, 0, math.max(0, #lines[cursorY] - maxVisibleChars + 10))
        end

        local keypressed
        keypressed = function(e)
            if e.key == "f1" then
                if modified then
                    -- TODO: Add confirmation dialog for unsaved changes
                end
                read(3).removeProcess("[NOTEPAD] - file edit path - "..path, function()
                    TERMINAL_ISVISIBLE(true)
                    REMOVE_EVENT("keypressed", keypressed)
                    write(is_open, false)
                    coroutine.yield()
                end)
            elseif e.key == "f5" then
                local content = table.concat(lines, "\n")

                if isType == "json" then
                    local success, parsed = pcall(read(2).decode, content)
                    if success and parsed then
                        content = read(2).encode(parsed)
                    end
                end
                
                read(4):open(path, "w", true):write(content, function(success, err)
                    if success then
                        modified = false
                    else
                        -- TODO: Show error message
                    end
                end)
            elseif e.key == "up" then
                cursorY = cursorY - 1
                updateCursor()
            elseif e.key == "down" then
                cursorY = cursorY + 1
                updateCursor()
            elseif e.key == "left" then
                cursorX = cursorX - 1
                updateCursor()
            elseif e.key == "right" then
                cursorX = cursorX + 1
                updateCursor()
            elseif e.key == "home" then
                cursorX = 1
                updateCursor()
            elseif e.key == "end" then
                cursorX = #lines[cursorY] + 1
                updateCursor()
            elseif e.key == "pageup" then
                cursorY = cursorY - maxVisibleLines
                updateCursor()
            elseif e.key == "pagedown" then
                cursorY = cursorY + maxVisibleLines
                updateCursor()
            elseif e.key == "backspace" then
                if cursorX > 1 then
                    local line = lines[cursorY]
                    lines[cursorY] = line:sub(1, cursorX-2) .. line:sub(cursorX)
                    cursorX = cursorX - 1
                    modified = true
                elseif cursorY > 1 then
                    local prevLineLength = #lines[cursorY-1]
                    lines[cursorY-1] = lines[cursorY-1] .. lines[cursorY]
                    table.remove(lines, cursorY)
                    cursorY = cursorY - 1
                    cursorX = prevLineLength + 1
                    modified = true
                end
                updateCursor()
            elseif e.key == "delete" then
                local line = lines[cursorY]
                if cursorX <= #line then
                    lines[cursorY] = line:sub(1, cursorX-1) .. line:sub(cursorX+1)
                    modified = true
                elseif cursorY < #lines then
                    lines[cursorY] = line .. lines[cursorY+1]
                    table.remove(lines, cursorY+1)
                    modified = true
                end
                updateCursor()
            elseif e.key == "return" then
                local line = lines[cursorY]
                local newLine = line:sub(cursorX)
                lines[cursorY] = line:sub(1, cursorX-1)
                table.insert(lines, cursorY+1, newLine)
                cursorY = cursorY + 1
                cursorX = 1
                modified = true
                updateCursor()
            elseif e.key == "space" then
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. " " .. line:sub(cursorX)
                cursorX = cursorX + 1
                modified = true
                updateCursor()
            elseif e.key == "tab" then
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. "  " .. line:sub(cursorX)
                cursorX = cursorX + 1
                modified = true
                updateCursor()
            elseif e.key and #e.key == 1 then
                local line = lines[cursorY]
                lines[cursorY] = line:sub(1, cursorX-1) .. e.key .. line:sub(cursorX)
                cursorX = cursorX + 1
                modified = true
                updateCursor()
            end
        end
        ADD_EVENT("keypressed", keypressed)

        write(is_open, true)
        while read(is_open) do
            coroutine.yield()
            CLEAR()
            
            ----- top bar ----
            DTX(5, 5, "File: "..path..(modified and " *" or ""), {255, 255, 255}, FONT_SCALE)
            DTX(width - 5 - (#topBarText * FONT_WIDTH), 5, topBarText, {255, 255, 255}, FONT_SCALE)
            DLN(0, 9 + FONT_HEIGHT, width, 9 + FONT_HEIGHT, {0, 255, 0})
            ------------------

            ---- lines -------
            local startLine = scrollY + 1
            local endLine = math.min(startLine + maxVisibleLines - 1, #lines)
            
            for i = startLine, endLine do
                local line = lines[i]
                local visibleText = line:sub(scrollX + 1, scrollX + maxVisibleChars)
                DTX(5, 12 + FONT_HEIGHT + (i - startLine) * FONT_HEIGHT, visibleText, {255, 255, 255}, FONT_SCALE)

                if i == cursorY then
                    local cursorPosX = cursorX - scrollX
                    if cursorPosX >= 1 and cursorPosX <= maxVisibleChars + 1 then
                        local cursorScreenX = 5 + (cursorPosX - 1) * FONT_WIDTH
                        local cursorScreenY = 12 + FONT_HEIGHT + (i - startLine) * FONT_HEIGHT
                        DRE(cursorScreenX, cursorScreenY, FONT_WIDTH-2, FONT_HEIGHT, {255, 255, 255})
                    end
                end
            end
            
            if scrollY > 0 then
                DTX(width - 15, 15, "↑", {200, 200, 200}, FONT_SCALE)
            end
            if scrollY < #lines - maxVisibleLines then
                DTX(width - 15, height - 15, "↓", {200, 200, 200}, FONT_SCALE)
            end
            if scrollX > 0 then
                DTX(5, height - 15, "←", {200, 200, 200}, FONT_SCALE)
            end
            if scrollX < #lines[cursorY] - maxVisibleChars then
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
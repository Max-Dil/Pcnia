local paintApp = {
    name = "Paint",
    version = "1.34",
    main = "main",
    iconText = "ART",
    iconTextColor = {255, 255, 255},
    system = true,
    scripts = {
        main = [[
local canvasWidth = MONITOR.resolution.width
local canvasHeight = MONITOR.resolution.height - 100

local canvasOffsetX, canvasOffsetY = 0, 0
local canvasScrollSpeed = 10
local canvasCols = 100
local canvasRows = 100
local isSettingSize = false
local newCanvasWidth = canvasCols
local newCanvasHeight = canvasRows

local pixelSize = 4
local color = {255, 255, 255}
local palette = {
    {0, 0, 0},       -- Black
    {255, 255, 255}, -- White
    {255, 0, 0},     -- Red
    {0, 255, 0},     -- Green
    {0, 0, 255},     -- Blue
    {255, 255, 0},   -- Yellow
    {255, 0, 255},   -- Magenta
    {0, 255, 255},   -- Cyan
    {128, 128, 128}, -- Gray
    {255, 165, 0}    -- Orange
}
local tool = "pencil" -- "pencil", "eraser", "fill", "picker"
local fileName = "untitled.pix"
local statusMessage = ""
local statusTimer = 0
local showGrid = true
local canvas = {}
local cursorX, cursorY = 0, 0
local isDrawing = false
local lastX, lastY = -1, -1

local is_load = false

local canvasCols = math.floor(canvasWidth / pixelSize)
local canvasRows = math.floor(canvasHeight / pixelSize)

for y = 1, canvasRows do
    canvas[y] = {}
    for x = 1, canvasCols do
        canvas[y][x] = {0, 0, 0}
    end
end

if read(1) == 0 then
    write(1, "")
else
    local savedData = read(1)
    if #savedData > 0 then
        local success, loaded = pcall(loadstring("return "..savedData))
        if success and type(loaded) == "table" then
            canvas = loaded
            canvasRows = #canvas
            if canvasRows > 0 then
                canvasCols = #canvas[1]
            end
        end
    end
end

local function updateDisplay()
    GPU:clear()

    DRE(0, 0, canvasWidth, 30, {50, 50, 50})
    DTX(10, 10, "Paint - "..fileName, {255, 255, 255}, 1)

    DRE(canvasWidth - 20, 10, 10, 10, {255, 0, 0})
    DRE(canvasWidth - 35, 10, 10, 10, {0, 100, 255})

    DRE(0, 30, canvasWidth, 20, {70, 70, 70})
    DTX(10, 35, "F1:Pencil F2:Eraser F3:Fill F4:Picker F5:Grid F6:F7:Size\nF8:Save F9:Load F10:New F11: SaveAs 1:Move F12:Resize", {200, 200, 200}, 1)

    local paletteStartY = canvasHeight + 40
    if paletteStartY + 20 > MONITOR.resolution.height then
        paletteStartY = MONITOR.resolution.height - 20
    end

    local statusBarY = paletteStartY + 30
    if statusBarY + 20 > MONITOR.resolution.height then
        statusBarY = MONITOR.resolution.height - 20
    end
    DRE(0, statusBarY, canvasWidth, 20, {40, 40, 40})
    DTX(10, statusBarY + 5, "Color: "..color[1]..","..color[2]..","..color[3].." | Tool: "..tool.." | Size: "..pixelSize, {150, 150, 150}, 1)

    if statusMessage ~= "" and statusTimer > 0 then
        LDX(statusMessage)
        DTX(canvasWidth/2 - (#X()*3), statusBarY - 20, X(), {0, 255, 0}, 1)
        statusTimer = statusTimer - 1
    end

    for y = 1, #canvas do
        for x = 1, #canvas[y] do
            local pixelX = 50 + (x-1)*pixelSize + canvasOffsetX
            local pixelY = 50 + (y-1)*pixelSize + canvasOffsetY
            if pixelX >= 0 and pixelX < canvasWidth and pixelY >= 50 and pixelY < canvasHeight + 50 then
                if canvas[y][x] then
                    DRE(pixelX, pixelY, pixelSize, pixelSize, canvas[y][x])

                    if showGrid then
                        DRE(pixelX, pixelY, 1, pixelSize, {50, 50, 50})
                        DRE(pixelX, pixelY, pixelSize, 1, {50, 50, 50})
                    end
                end
            end
        end
    end

    if isSettingSize then
        DRE(canvasWidth/2 - 100, canvasHeight/2 - 50, 200, 100, {70, 70, 70})
        DTX(canvasWidth/2 - 90, canvasHeight/2 - 40, "Set Canvas Size:", {255, 255, 255}, 1)
        DTX(canvasWidth/2 - 90, canvasHeight/2 - 20, "Width: "..newCanvasWidth, {255, 255, 255}, 1)
        DTX(canvasWidth/2 - 90, canvasHeight/2, "Height: "..newCanvasHeight, {255, 255, 255}, 1)
        DTX(canvasWidth/2 - 90, canvasHeight/2 + 20, "Enter: Confirm Esc: Cancel", {200, 200, 200}, 1)
    end

    DRE(0, paletteStartY - 5, canvasWidth, 30, {40, 40, 40})
    
    for i, col in ipairs(palette) do
        local xPos = 10 + (i-1)*25
        if xPos + 20 > canvasWidth then break end
        DRE(xPos, paletteStartY, 20, 20, col)
        if col[1] == color[1] and col[2] == color[2] and col[3] == color[3] then
            DTX(xPos + 2, paletteStartY + 2, "S", {255, 255, 255}, 1)
        end
    end

    if cursorX >= 0 and cursorY >= 0 and cursorX <= canvasWidth and cursorY <= canvasHeight then
        local canvasX = math.floor(cursorX/pixelSize) + 1
        local canvasY = math.floor((cursorY-50)/pixelSize) + 1
        
        if canvasX >= 1 and canvasX <= #canvas[1] and canvasY >= 1 and canvasY <= #canvas then
            DRE((canvasX-1)*pixelSize, 50 + (canvasY-1)*pixelSize, pixelSize, pixelSize, 
                {255 - canvas[canvasY][canvasX][1], 
                 255 - canvas[canvasY][canvasX][2], 
                 255 - canvas[canvasY][canvasX][3]})
        end
    end

    return nil
end

local function resizeCanvas(newWidth, newHeight)
    local newCanvas = {}
    for y = 1, newHeight do
        newCanvas[y] = {}
        for x = 1, newWidth do
            if y <= #canvas and x <= #canvas[y] then
                newCanvas[y][x] = canvas[y][x] or {0,0,0}
            else
                newCanvas[y][x] = {0, 0, 0}
            end
        end
    end
    canvas = newCanvas
    canvasCols = newWidth
    canvasRows = newHeight
    canvasOffsetX, canvasOffsetY = 0, 0
end

local function showStatus(message, duration)
    statusMessage = message
    statusTimer = duration or 60
end

local function saveFile(path)
    local file = FILE_SYSTEM:open(path, "w", true)

    local serialized = json.encode(canvas)
    file:write(serialized, function(success)
        if success then
            fileName = path
            showStatus("Saved successfully: "..fileName, 60)
            write(1, serialized)
            updateDisplay()
        else
            showStatus("Save failed!", 60)
        end
    end)
end

local function saveFileAs()
    is_load = true
    isDrawing = false
    openFileDialog(function(file)
        if file then
            saveFile(file.path)
        end
        is_load = false
    end, true)
end

local function loadFilePath(file)
    is_load = false
    isDrawing = false
    if file then
        local success, loaded = pcall(json.decode, file.data)
        if success and type(loaded) == "table" then
            canvas = loaded
            fileName = file.path
            write(1, file.data)
            showStatus("Loaded: "..fileName, 60)
            updateDisplay()
        else
            fileName = file.path
            showStatus("Invalid file format", 60)
        end
    end
end

local function loadFile()
    is_load = true
    isDrawing = false
    openFileDialog(function(file)
        loadFilePath(file)
    end)
end
APP.loadFilePath = loadFilePath

local function newFile()
    for y = 1, #canvas do
        for x = 1, #canvas[y] do
            canvas[y][x] = {0, 0, 0}
        end
    end
    fileName = "untitled.pix"
    write(1, "")
    showStatus("New canvas created", 60)
    updateDisplay()
end

local function floodFill(x, y, targetColor, replacementColor)
    if x < 1 or x > #canvas[1] or y < 1 or y > #canvas then return end
    if canvas[y][x][1] ~= targetColor[1] or 
       canvas[y][x][2] ~= targetColor[2] or 
       canvas[y][x][3] ~= targetColor[3] then return end
    if replacementColor[1] == targetColor[1] and 
       replacementColor[2] == targetColor[2] and 
       replacementColor[3] == targetColor[3] then return end
    
    canvas[y][x] = {replacementColor[1], replacementColor[2], replacementColor[3]}
    
    floodFill(x+1, y, targetColor, replacementColor)
    floodFill(x-1, y, targetColor, replacementColor)
    floodFill(x, y+1, targetColor, replacementColor)
    floodFill(x, y-1, targetColor, replacementColor)
end

local function drawLine(x1, y1, x2, y2)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy

    while true do
        if is_load then break end
        if x1 >= 1 and x1 <= #canvas[1] and y1 >= 1 and y1 <= #canvas then
            if tool == "pencil" then
                canvas[y1][x1] = {color[1], color[2], color[3]}
            elseif tool == "eraser" then
                canvas[y1][x1] = {0, 0, 0}
            end
        end
        if x1 == x2 and y1 == y2 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
end

addEvent("keypressed", function(key)
    if is_load then return end

    if isSettingSize then
        if key == "up" then
            newCanvasHeight = math.max(10, newCanvasHeight + 1)
        elseif key == "down" then
            newCanvasHeight = math.max(10, newCanvasHeight - 1)
        elseif key == "right" then
            newCanvasWidth = math.max(10, newCanvasWidth + 1)
        elseif key == "left" then
            newCanvasWidth = math.max(10, newCanvasWidth - 1)
        elseif key == "return" then
            resizeCanvas(newCanvasWidth, newCanvasHeight)
            isSettingSize = false
            showStatus("Canvas resized to "..newCanvasWidth.."x"..newCanvasHeight, 60)
        elseif key == "escape" then
            isSettingSize = false
        end
        updateDisplay()
        return
    end

    if tool == "move" then
        if key == "up" then
            canvasOffsetY = canvasOffsetY + canvasScrollSpeed
        elseif key == "down" then
            canvasOffsetY = canvasOffsetY - canvasScrollSpeed
        elseif key == "left" then
            canvasOffsetX = canvasOffsetX + canvasScrollSpeed
        elseif key == "right" then
            canvasOffsetX = canvasOffsetX - canvasScrollSpeed
        end
        updateDisplay()
    end

    if key == "f1" then
        tool = "pencil"
    elseif key == "f2" then
        tool = "eraser"
    elseif key == "f3" then
        tool = "fill"
    elseif key == "f4" then
        tool = "picker"
    elseif key == "f5" then
        showGrid = not showGrid
    elseif key == "f6" then
        pixelSize = math.max(1, pixelSize - 1)
        canvasCols = math.floor(canvasWidth / pixelSize)
        canvasRows = math.floor(canvasHeight / pixelSize)
    elseif key == "f7" then
        pixelSize = math.min(8, pixelSize + 1)
        canvasCols = math.floor(canvasWidth / pixelSize)
        canvasRows = math.floor(canvasHeight / pixelSize)
    elseif key == "f8" then
        print(fileName)
        if fileName == "untitled.pix" then
            saveFileAs()
        else
            saveFile(fileName)
        end
    elseif key == "f9" then
        loadFile()
    elseif key == "f10" then
        newFile()
    elseif key == "f11" then
        saveFileAs()
    elseif key == "1" then
        tool = "move"
        showStatus("Move mode - use arrow keys to pan canvas", 60)
    elseif key == "f12" then
        isSettingSize = true
        newCanvasWidth = canvasCols
        newCanvasHeight = canvasRows
        showStatus("Resize mode - use arrow keys to adjust size", 60)
    end
    
    updateDisplay()
end)

addEvent("mousemoved", function(x, y)
    if is_load then return end
    cursorX, cursorY = x, y
    local canvasX = math.floor((x-50 - canvasOffsetX)/pixelSize) + 1
    local canvasY = math.floor((y-50 - canvasOffsetY)/pixelSize) + 1
    
    if isDrawing and tool ~= "fill" and tool ~= "picker" then
        if lastX ~= -1 and lastY ~= -1 then
            drawLine(lastX, lastY, canvasX, canvasY)
                updateDisplay()
        else
            if canvasX >= 1 and canvasX <= #canvas[1] and canvasY >= 1 and canvasY <= #canvas then
                if tool == "pencil" then
                    canvas[canvasY][canvasX] = {color[1], color[2], color[3]}
                elseif tool == "eraser" then
                    canvas[canvasY][canvasX] = {0, 0, 0}
                end
                updateDisplay()
            end
        end
        lastX, lastY = canvasX, canvasY
    end
end)

addEvent("mousepressed", function(x, y, button)
    if is_load then return end
    local paletteStartY = canvasHeight + 40
    if paletteStartY + 40 > MONITOR.resolution.height then
        paletteStartY = MONITOR.resolution.height - 40
    end
    
    if y >= paletteStartY and y <= paletteStartY + 20 then
        for i, col in ipairs(palette) do
            local xPos = 10 + (i-1)*25
            if x >= xPos and x <= xPos + 20 then
                color = {col[1], col[2], col[3]}
                updateDisplay()
                return
            end
        end
    end

    if button == 1 and y >= 50 and y <= 50 + canvasHeight then
        isDrawing = true
        lastX, lastY = -1, -1
        local canvasX = math.floor((x-50 - canvasOffsetX)/pixelSize) + 1
        local canvasY = math.floor((y-50 - canvasOffsetY)/pixelSize) + 1

        if canvasX >= 1 and canvasX <= #canvas[1] and canvasY >= 1 and canvasY <= #canvas then
            if tool == "pencil" then
                canvas[canvasY][canvasX] = {color[1], color[2], color[3]}
            elseif tool == "eraser" then
                canvas[canvasY][canvasX] = {0, 0, 0}
            elseif tool == "fill" then
                floodFill(canvasX, canvasY, canvas[canvasY][canvasX], color)
            elseif tool == "picker" then
                color = {canvas[canvasY][canvasX][1], canvas[canvasY][canvasX][2], canvas[canvasY][canvasX][3]}
                showStatus("Color picked: "..color[1]..","..color[2]..","..color[3], 60)
            end
        end
    end

    updateDisplay()
end)

addEvent("mousereleased", function()
    if is_load then isDrawing = false lastX, lastY = -1, -1 return end
    isDrawing = false
    lastX, lastY = -1, -1
    write(1, serialize(canvas))
    updateDisplay()
end)

function serialize(t)
    local result = json.encode(t)
    return result
end

while true do
    SLEEP(0.05)
end
]]
    }
}

return paintApp
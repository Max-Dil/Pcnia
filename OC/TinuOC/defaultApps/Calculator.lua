local calculatorApp = {
    name = "Calculator",
    version = "1.2",
    main = "main",
    iconText = "",
    iconTextColor = {255, 255, 255},
    icon = json.decode('[[[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[255,100,100],[255,100,100],[255,100,100],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[255,100,100],[255,100,100],[255,100,100],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[255,100,100],[255,100,100],[255,100,100],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[255,100,100],[255,100,100],[255,100,100],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[255,100,100],[255,100,100],[255,100,100],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[100,100,255],[100,100,255],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[100,100,255],[100,100,255],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[200,255,200],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[100,100,255],[100,100,255],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[100,100,255],[100,100,255],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[150,150,150],[150,150,150],[150,150,150],[0,0,0],[100,100,255],[100,100,255],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[50,150,50],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[150,150,150],[200,200,200],[150,150,150],[150,150,150],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0],[200,200,200],[200,200,200],[200,200,200],[0,0,0]],[[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]]'),
    scripts = {
        main = [[
local displayValue = "0"
local memoryValue = 0
local lastOperation = nil
local resetDisplay = false
local history = {}

local buttonWidth = 50
local buttonHeight = 40
local buttonMargin = 5

local function updateDisplay()
    GPU:clear()

    DRE(0, 0, MONITOR.resolution.width, 60, {40, 40, 40})

    DTX(10, 10, displayValue, {255, 255, 255}, 2)

    if memoryValue ~= 0 then
        DTX(MONITOR.resolution.width - 60, 10, "M", {150, 150, 150}, 2)
    end

    if #history > 0 then
        local startY = 70
        for i = math.max(1, #history - 2), #history do
            DTX(10, startY, history[i], {150, 150, 150}, 1)
            startY = startY + 20
        end
    end

    local buttons = {
        {"7", "8", "9", "/", "C"},
        {"4", "5", "6", "*", "M+"},
        {"1", "2", "3", "-", "M-"},
        {"0", ".", "=", "+", "MR"}
    }
    
    local startX = 10
    local startY = 120
    
    for row = 1, 4 do
        for col = 1, 5 do
            local btnText = buttons[row][col]
            local btnX = startX + (col-1)*(buttonWidth + buttonMargin)
            local btnY = startY + (row-1)*(buttonHeight + buttonMargin)

            local btnColor = {70, 70, 70}
            if btnText == "C" then
                btnColor = {200, 50, 50}
            elseif btnText == "=" then
                btnColor = {50, 150, 50}
            elseif string.find("+-*/", btnText) then
                btnColor = {50, 50, 150}
            elseif string.find("M", btnText) then
                btnColor = {100, 50, 150}
            end
            
            DRE(btnX, btnY, buttonWidth, buttonHeight, btnColor)
            DTX(btnX + buttonWidth/2 - 5, btnY + buttonHeight/2 - 5, btnText, {255, 255, 255}, 1)
        end
    end

    DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
    DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
    
    return nil
end

local function calculate()
    local current = tonumber(displayValue)
    if not lastOperation or not current then return end
    
    local result = 0
    local operationText = ""
    
    if lastOperation == "+" then
        result = memoryValue + current
        operationText = memoryValue.." + "..current.." = "..result
    elseif lastOperation == "-" then
        result = memoryValue - current
        operationText = memoryValue.." - "..current.." = "..result
    elseif lastOperation == "*" then
        result = memoryValue * current
        operationText = memoryValue.." * "..current.." = "..result
    elseif lastOperation == "/" then
        if current ~= 0 then
            result = memoryValue / current
            operationText = memoryValue.." / "..current.." = "..result
        else
            operationText = "Error: Division by zero"
            result = 0
        end
    end
    
    table.insert(history, operationText)
    if #history > 10 then table.remove(history, 1) end
    
    displayValue = tostring(result)
    memoryValue = result
    resetDisplay = true
end

addEvent("mousepressed", function(x, y, button)
    if button ~= 1 then return end
    
    local buttons = {
        {"7", "8", "9", "/", "C"},
        {"4", "5", "6", "*", "M+"},
        {"1", "2", "3", "-", "M-"},
        {"0", ".", "=", "+", "MR"}
    }
    
    local startX = 10
    local startY = 120
    
    for row = 1, 4 do
        for col = 1, 5 do
            local btnX = startX + (col-1)*(buttonWidth + buttonMargin)
            local btnY = startY + (row-1)*(buttonHeight + buttonMargin)
            
            if x >= btnX and x <= btnX + buttonWidth and y >= btnY and y <= btnY + buttonHeight then
                local btnText = buttons[row][col]
                
                if string.find("0123456789", btnText) then
                    if displayValue == "0" or resetDisplay then
                        displayValue = btnText
                        resetDisplay = false
                    else
                        displayValue = displayValue .. btnText
                    end
                
                elseif btnText == "." then
                    if not string.find(displayValue, "%.") then
                        displayValue = displayValue .. "."
                    end
                
                elseif btnText == "C" then
                    displayValue = "0"
                    memoryValue = 0
                    lastOperation = nil
                
                elseif string.find("+-*/", btnText) then
                    if lastOperation then
                        calculate()
                    end
                    memoryValue = tonumber(displayValue)
                    lastOperation = btnText
                    resetDisplay = true
                
                elseif btnText == "=" then
                    if lastOperation then
                        calculate()
                        lastOperation = nil
                    end
                
                elseif btnText == "M+" then
                    memoryValue = memoryValue + tonumber(displayValue)
                    resetDisplay = true
                
                elseif btnText == "M-" then
                    memoryValue = memoryValue - tonumber(displayValue)
                    resetDisplay = true
                
                elseif btnText == "MR" then
                    displayValue = tostring(memoryValue)
                    resetDisplay = true
                end
                
                updateDisplay()
                return
            end
        end
    end
end)

addEvent("keypressed", function(key)
    if string.find("0123456789", key) then
        if displayValue == "0" or resetDisplay then
            displayValue = key
            resetDisplay = false
        else
            displayValue = displayValue .. key
        end
    
    elseif key == "." then
        if not string.find(displayValue, "%.") then
            displayValue = displayValue .. "."
        end
    
    elseif key == "escape" or key == "c" then
        displayValue = "0"
        memoryValue = 0
        lastOperation = nil
    
    elseif string.find("+-*/", key) then
        if lastOperation then
            calculate()
        end
        memoryValue = tonumber(displayValue)
        lastOperation = key
        resetDisplay = true
    
    elseif key == "return" or key == "=" then
        if lastOperation then
            calculate()
            lastOperation = nil
        end
    
    elseif key == "backspace" then
        if #displayValue > 1 then
            displayValue = string.sub(displayValue, 1, -2)
        else
            displayValue = "0"
        end
    end
    
    updateDisplay()
end)

updateDisplay()

while true do
    SLEEP(0.05)
end
]]
    }
}

return calculatorApp
local app = {}
local process
local fs
local function split(str, delimiter)
    local result = {}
    if not str then return result end
    for part in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

--[[
Структура приложений

name - название
version - версия
title - описание
code - основной код
modules - используемые модули

API:
ADD_COMMAND(name, listener)
REMOVE_COMMAND(name)
TERMINAL(command, args, listener)
TERMINAL_ISVISIBLE(isVisible)
ADD_EVENT(name, listener)
REMOVE_EVENT(name, listener)
CLOSE()
RESOLUTION()-- return scrennWidth, scrennHeight
RESOLVE_PATH(currentDir, targetDir)
]]

app.init = function (proc, listener)
    proc.addProcess("[OS] Init app module", function ()
        write(9, app)
        process = read(3)
        fs = read(4)

        write(10, {})
        listener(TRUE)

        process.removeProcess("[OS] Init app module")
    end, function (success, error)
        if not success then
            listener(NIL, "[OS] Error init app module: "..error)
            print("[OS] Error init app module: "..error)
        end
    end)
end

local function readInput(callcack, listener)
    process.addProcess("[APP] readInput", function ()

        read(8)["y"] = function (shell, args, callback)
	        process.addProcess("[APP][COMMANDS] - Y", function ()
                listener(true)
	        	read(8)["y"] = nil
                read(8)["n"] = nil
                process.removeProcess("[APP][COMMANDS] - Y")
                process.removeProcess("[APP] readInput")
	        end)
        end

        read(8)["n"] = function (shell, args, callback)
	        process.addProcess("[APP][COMMANDS] - N", function ()
                listener(false, "Application launch denied")
                read(8)["y"] = nil
                read(8)["n"] = nil
                process.removeProcess("[APP][COMMANDS] - N")
                process.removeProcess("[APP] readInput")
	        end)
        end
    end, function (success, error)
        if not success then
            print(error)
            listener(NIL, error)
        end
    end)
end

app.run = function (path, listener)
    listener = listener or function()end
    process.addProcess("[APP] Run app to "..path, function ()
        LDA(read(10))
        local isSuccess = true
        if not A()[path] or not A()[path].data then
            local load = true
            app.load(path, function (success, error, isText)
                if isText then
                    listener(NIL, error)
                    return
                end
                if not success then
                    listener(NIL, error)
                    isSuccess = false
                end
                load = false
            end)
            while load do coroutine.yield() end
        end
        if isSuccess then
            LDA(read(10))
            local success, error
            if A()[path].ext == "json" then
                success, error = pcall(read(2).decode, A()[path].data)
            else
                local f = loadstring("return " .. A()[path].data)
                success, error = pcall(f)
            end
            if not success or A()[path].data == "" then
                listener(NIL, A()[path].data == "" and "Error: broken package" or error)
                process.removeProcess("[APP] Run app to "..path)
                return
            end

            LDX(error)

local defaultCode = [[
local __APP__NAME__ = "]]..X().name..[["
local __APP__MODULES__ = read(2).decode(']]..read(2).encode(X().modules)..[[')
local __APP__VISIBLE__ = false

local EVENTS = {}
local PROCESSES = {}
table.insert(PROCESSES, "]]..path..[[")
table.insert(PROCESSES, "]].."[APP] Run app to "..path..[[")

local RAM = read(0)

local CLOSE
local CLOSE_EVENT = function(e)
    if e.key == "escape" then
        CLOSE()
    end
end
CLOSE = function()
    if __APP__VISIBLE__ then
        if read(8).app[__APP__NAME__] then
            read(8).app[__APP__NAME__] = NIL
        end
        read(5).rm_event("keypressed", CLOSE_EVENT)
        for key, value in pairs(EVENTS) do
            for index, value2 in ipairs(EVENTS[key]) do
                read(5).rm_event(key, value2)
            end
        end
        __APP__VISIBLE__ = false
        read(7).isVisible = TRUE
        for index, value in ipairs(PROCESSES) do
            read(3).removeProcess(value)
        end
    end
end
read(5).mk_event("keypressed", CLOSE_EVENT)

local function ALLOC(count)
    local addr = RAM.TEMP()
    if count then
        for i = addr+1, addr + count, 1 do
            A().TEMP()
        end
    end
    return addr
end
local function ADD_COMMAND(n, l)
    local name, listener = ALLOC(), ALLOC()
    write(name, n)
    write(listener, l)

    if not read(8).app[__APP__NAME__] then
        read(8).app[__APP__NAME__] = {}
    end
    if read(8).app[__APP__NAME__][read(name)] then
        return
    end
    read(8).app[__APP__NAME__][read(name)] = read(listener)
    RAM.FREE(name)
    RAM.FREE(listener)
end
local function REMOVE_COMMAND(n)
    local name = ALLOC()
    write(name, n)

    if not read(8).app[__APP__NAME__] then
        return
    end
    read(8).app[__APP__NAME__][read(name)] = NIL

    RAM.FREE(name)
end
local function TERMINAL(com, arg, l)
    local command, args, listener = ALLOC(), ALLOC(), ALLOC()
    write(command, com)
    write(args, arg)
    write(listener, l)

    read(8)[read(command)]({}, read(args), read(listener))

    RAM.FREE(args)
    RAM.FREE(command)
    RAM.FREE(listener)
end
local function TERMINAL_ISVISIBLE(isVis)
    local isVisible = ALLOC()
    write(isVisible, isVis)

    __APP__VISIBLE__ = not read(isVisible)
    read(7).isVisible = read(isVisible)

    RAM.FREE(isVisible)
end
local function ADD_EVENT(n, l)
    local name, listener = ALLOC(), ALLOC()
    write(name, n)
    write(listener, l)

    if not EVENTS[read(name)] then
        EVENTS[read(name)] = {}
    end
    table.insert(EVENTS[read(name)], read(listener))
    read(5).mk_event(read(name), read(listener))

    RAM.FREE(name)
    RAM.FREE(listener)
end
local function REMOVE_EVENT(n, l)
    local name, listener = ALLOC(), ALLOC()

    write(name, n)
    write(listener, l)

    if not EVENTS[read(name)] then
        EVENTS[read(name)] = {}
    end
    for i = #EVENTS[read(name)], 1, -1 do
        if EVENTS[read(name)][i] == read(listener) then
            table.remove(EVENTS[read(name)], i)
            break
        end
    end
    read(5).rm_event(read(name), read(listener))

    RAM.FREE(name)
    RAM.FREE(listener)
end

local function CLEAR(r, g ,b)
    if not read(7).isVisible then
        read(1).devices.GPU:clear(r, g ,b)
    end
end

local function RESOLUTION()
    return read(1).devices.GPU.resolution.width, read(1).devices.GPU.resolution.height
end

local function RESOLVE_PATH(currentDir, targetDir)
    return read(8).resolvePath(currentDir, targetDir)
end
]]..require("OC.Tinu.core.packages")..[[

local _G = {
    ALLOC = ALLOC,
    ADD_COMMAND = ADD_COMMAND,
    REMOVE_COMMAND = REMOVE_COMMAND,
    ADD_EVENT = ADD_EVENT,
    REMOVE_EVENT = REMOVE_EVENT,
    TERMINAL = TERMINAL,
    TERMINAL_ISVISIBLE = TERMINAL_ISVISIBLE,

    LDX = LDX,
    LDA = LDA,
    LDY = LDY,
    X = X,
    A = A,
    Y = Y,

    READ = function(addr, size)
        if addr <= 10 then
            return 0
        end
        return read(addr, size)
    end,
    WRITE= function(addr, value)
        if addr <= 10 then
            return 0
        end
        return write(addr, value)
    end,
    FREE = function(addr, count)
        if addr <= 10 then
            return 0
        end
        return RAM.FREE(addr, count)
    end,
    ADD = ADD, -- +
    SUB = SUB, -- -
    MUL = MUL, -- *
    DIV = DIV, -- /
    AND = AND,
    OR = OR,
    XOR = XOR,
    NOT = NOT,
    SHL = SHL,
    SHR = SHR,
    CMP = CMP,
    IF = IF,
    NIL = NIL,
    TRUE = TRUE,
    FALSE = FALSE,
    DRW = DRW,
    DTX = DTX,
    DRE = DRE,
    DRM = DRM,
    DLN = DLN,
    SLEEP = SLEEP,
    SR = SR,
    SP = SP,
}
for _, module_name in ipairs(__APP__MODULES__) do
    if packages[module_name] then
        for k, v in pairs(packages[module_name]) do
            _G[k] = v
        end
    end
end

setfenv(1, setmetatable({}, {__index =_G}))
]]
local code =
defaultCode..X().code
            -- Запуск
            print(X().code)
            print(#split(defaultCode, "\n"))
            local f, error = loadstring(code, path)
            local isSucces = true
            if f then
                process.addProcess(path, f, function (success, error)
                    SLEEP(0.1)
                    if not success then
                        listener(NIL, error)
                        process.removeProcess(path)
                        isSucces = false
                    end
                end)
            else
                listener(NIL, error)
                process.removeProcess("[APP] Run app to "..path)
                return
            end
            if isSucces then
                local appMemory = read(0).TEMP()
                write(appMemory, error)
                A()[path].memory = appMemory
                listener(TRUE)
            end
        end
        process.removeProcess("[APP] Run app to "..path)
    end, function (success, error)
        if not success then
            listener(NIL, "Error: "..error)
            print("Error run to app: "..path,"Error: "..error)
        end
    end)
end

app.unload = function (path, listener)
    listener = listener or function() end
    process.addProcess("[APP] Unload app "..path, function ()
        LDA(read(10))

        if not A()[path] then
            listener(NIL, "Error: App not loaded")
            process.removeProcess("[APP] Unload app "..path)
            return
        end

        if A()[path].memory then
            local appData
            local success, error
            if A()[path].ext == "json" then
                success, error = pcall(read(2).decode, A()[path].data)
                if success then appData = error end
            else
                local f = loadstring("return " .. A()[path].data)
                success, error = pcall(f)
                if success then appData = error end
            end
            
            if success and appData then
                local appName = appData.name

                process.removeProcess(path)
                if read(8).app[appName] then
                    read(8).app[appName] = nil
                end

                read(0).FREE(A()[path].memory)
            end
        end
        
        A()[path] = nil
        write(10, A())
        
        listener(TRUE)
        process.removeProcess("[APP] Unload app "..path)
    end, function (success, error)
        if not success then
            listener(NIL, "Error: "..error)
            print("Error unloading app: "..path, "Error: "..error)
        end
    end)
end

app.load = function (path, listener)
    listener = listener or function()end
    process.addProcess("[APP] Load app to "..path, function ()
        local file = fs:open(path, "r", true)
        file:read(function (data)
            if not data then
                listener(NIL, "Error: Not found")
                return
            end
            if data == "" then
                listener(NIL, "Error: Empty file")
                return
            end

            local success, error
            if file.fileExt == "app" then
                local f = loadstring("return " .. data)
                success, error = pcall(f)
            else
                success, error = pcall(read(2).decode, data)
            end
            if not success or data == "" then
                listener(NIL, data == "" and "Error: broken package" or error)
                process.removeProcess("[APP] Load app to "..path)
                return
            end
            LDX(error)

            if read(1).__shell_autoloads_app_premission ~= true then
                if X().modules and #X().modules > 0 then
                    local monitorWidth = read(1).devices.MONITOR.resolution.width
                    local charWidth = 7
                    local maxCharsPerLine = math.floor(monitorWidth / charWidth)

                    listener(NIL, "======== Title ========", TRUE)
                    local titleLines = split(X().title or "No title", "\n")
                    for index, value in ipairs(titleLines) do
                        listener(NIL, value, TRUE)
                    end
                    listener(NIL, "======== End ========", TRUE)
                    listener(NIL, "You allow access to these modules?", TRUE)
                    listener(NIL, "Modules:", TRUE)
                
                    local dangerousModules = {
                        ["oc"] = "oc(dangerous!!!)",
                        ["luajit"] = "luajit(dangerous)",
                        ["processes"] = "processes(dangerous!!!)",
                        ["commands"] = "commands(dangerous)",
                        ["app"] = "app(dangerous)",
                        ["fs"] = "fs(dangerous!!)",
                    }
                    local currentLine = ""
                    for i, module in ipairs(X().modules) do
                        local displayModule = module
                        if dangerousModules[module] then
                            displayModule = dangerousModules[module]
                        end

                        if #currentLine + #displayModule + 2 > maxCharsPerLine then
                            listener(NIL, currentLine, TRUE)
                            currentLine = displayModule
                        else
                            if currentLine ~= "" then
                                currentLine = currentLine .. ", " .. displayModule
                            else
                                currentLine = displayModule
                            end
                        end
                    end

                    if currentLine ~= "" then
                        listener(NIL, currentLine, TRUE)
                    end

                    listener(NIL, "Write [y/n]", TRUE)

                    local waitResult = true
                    local isSuccess = true
                    readInput(listener, function(success, error)
                        if success then
                            waitResult = false
                            isSuccess = true
                        else
                            listener(NIL, error)
                            process.removeProcess("[APP] Load app to "..path)
                            isSuccess = false
                            waitResult = false
                        end
                    end)

                    while waitResult do
                        coroutine.yield()
                        SLEEP(0.2)
                    end

                    if not isSuccess then
                        return
                    end
                end
            end

            LDA(read(10))
            A()[path] = {
                data = data,
                ext = file.fileExt == "app" and "app" or "json"
            }
            write(10, A())
            listener(TRUE)
        end)
        process.removeProcess("[APP] Load app to "..path)
    end, function (success, error)
        if not success then
            listener(NIL, "Error: "..error)
            print("Error load to app: "..path,"Error: "..error)
        end
    end)
end

return app
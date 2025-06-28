local app = {}
local process
local fs

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
            local success, error = pcall(json.decode, A()[path].data)
            if not success or A()[path].data == "" then
                listener(NIL, A()[path].data == "" and "Error: broken package" or error)
                process.removeProcess("[APP] Run app to "..path)
                return
            end

            LDX(error)

            -- Запуск
            local f, error = loadstring(
[[
local __APP__NAME__ = "]]..X().name..[["
local __APP__MODULES__ = require("OC.Tinu.core.components.json").decode(']]..require("OC.Tinu.core.components.json").encode(X().modules)..[[')
local function ALLOC(count)
    local addr = read(0).TEMP()
    write(addr, 0)
    if count then
        for i = 1, count, 1 do
            write(addr+i, 0)
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
    free(name)
    free(listener)
end
local function REMOVE_COMMAND(n)
    local name = ALLOC()
    write(name, n)

    if not read(8).app[__APP__NAME__] then
        return
    end
    read(8).app[__APP__NAME__][read(name)] = NIL

    free(name)
end
local function TERMINAL(com, arg, l)
    local command, args, listener = ALLOC(), ALLOC(), ALLOC()
    write(command, com)
    write(args, arg)
    write(listener, l)

    read(8)[read(command)]({}, read(args), read(listener))

    free(args)
    free(command)
    free(listener)
end
local function TERMINAL_ISVISIBLE(isVis)
    local isVisible = ALLOC()
    write(isVisible, isVis)

    read(11).isVisible = read(isVisible)

    free(isVisible)
end
local function ADD_EVENT(n, l)
    local name, listener = ALLOC(), ALLOC()
    write(name, n)
    write(listener, l)

    read(5).mk_event(read(name), read(listener))

    free(name)
    free(listener)
end
local function REMOVE_EVENT(n, l)
    local name, listener = ALLOC(), ALLOC()

    write(name, n)
    write(listener, l)

    read(5).rm_event(read(name), read(listener))

    free(name)
    free(listener)
end

local _G = {
    print = print,
    pcall = pcall,
    coroutine = {
        yield = coroutine.yield,
    },
    os = os,
    table = table,
    unpack = unpack,
    ipairs = ipairs,
    pairs = pairs,
 
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
        -- if addr <= 11 then
        --     return 0
        -- end
        return read(addr, size)
    end,
    WRITE= function(addr, value)
        -- if addr <= 11 then
        --     return 0
        -- end
        return write(addr, value)
    end,
    FREE = function(addr, count)
        -- if addr <= 11 then
        --     return 0
        -- end
        return free(addr, count)
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
setfenv(1, setmetatable({}, {__index =_G}))
]]..X().code
            , path)
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
            local appData = json.decode(A()[path].data)
            local appName = appData.name

            process.removeProcess(path)
            if read(8).app[appName] then
                read(8).app[appName] = nil
            end

            free(A()[path].memory)
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

            local success, error = pcall(json.decode, data)
            if not success or data == "" then
                listener(NIL, data == "" and "Error: broken package" or error)
                return
            end
            LDX(error)

            if X().modules and #X().modules > 0 then
                local monitorWidth = read(1).devices.MONITOR.resolution.width
                local charWidth = 7
                local maxCharsPerLine = math.floor(monitorWidth / charWidth)
                
                listener(NIL, "You allow access to these modules?", TRUE)
                listener(NIL, "Modules:", TRUE)
            
                local currentLine = ""
                for i, module in ipairs(X().modules) do
                    if #currentLine + #module + 2 > maxCharsPerLine then 
                        listener(NIL, currentLine, TRUE)
                        currentLine = module
                    else
                        if currentLine ~= "" then
                            currentLine = currentLine .. ", " .. module
                        else
                            currentLine = module
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

            LDA(read(10))
            A()[path] = {
                data = data,
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
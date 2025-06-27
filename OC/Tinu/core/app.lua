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

app.run = function (path, listener)
    listener = listener or function()end
    process.addProcess("[APP] Run app to "..path, function ()
        LDA(read(10))
        local isSuccess = true
        if not A()[path] or not A()[path].data then
            local load = true
            app.load(path, function (success, error)
                if not success then
                    listener(NIL, "Error: "..error)
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
]]..X().code
            , path)
            local isSucces = true
            if f then
                process.addProcess(path, f, function (success, error)
                    if not success then
                        listener(NIL, error)
                        process.removeProcess(path)
                        isSucces = false
                    end
                    return
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
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
        if not A()[path] then
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
            -- запуск
            LDA(read(10))
            local success, error = pcall(json.encode, A()[path])
            if not success or A()[path] == "" then
                listener(NIL, A()[path] == "" and "Error: broken package" or error)
                process.removeProcess("[APP] Run app to "..path)
                return
            end
            listener(TRUE)
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

            local success, error = pcall(json.encode, data)
            if not success or data == "" then
                listener(NIL, data == "" and "Error: broken package" or error)
                return
            end

            LDA(read(10))
            A()[path] = data
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
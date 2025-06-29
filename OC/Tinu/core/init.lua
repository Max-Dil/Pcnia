local OC = {
    devices = {},
}

OC.init = function(config)
    config.gpu.driver = "Unakoda"
    OC.config = config
    OC.devices = {
        CPU = config.cpu,
        GPU = config.gpu:init(config.cpu),
        MB = config.mother:init(config.cpu),
        MONITOR = config.monitor:init(config.gpu),
        RAM = config.ram:init(config.mother),
        COOLER = config.cooler:init(config.cpu, config.mother),
        PSU = config.block:init(config.mother),
        DISK = config.disk:init(config.mother),
    }
    config.cpu:init()
    config.cpu:setMotherboard(config.mother)
    config.mother:attachCooler(config.cooler)
    config.cpu:setGPU(config.gpu)
    config.mother.gpu = config.gpu
    config.mother.monitor = config.monitor
    config.block.monitor = config.monitor
    config.mother:attachStorage(config.disk)
    config.mother:addInterrupt("TIMER", {interval = 1})

    config.gpu:setResolution(config.monitor.resolution.width, config.monitor.resolution.height)

    config.cpu.updateComponents = function(dt)
        config.ram:update(dt)
        config.disk:update(dt)
    end

    -- config.disk:loadFromFile("TinuOC")
    config.cpu:addThread(function ()
        LDA({255, 255, 255})

        LDX("Load Tinu")
        DTX(10, 10, X(), A(), 2)

        write(0, require("OC.Tinu.core.ram"))
        LDA(read(0))

        read(11, function (addr, count)
            A().FREE(addr, count)
            free(addr, count)
        end)
        A().init(OC, function () -- init ram system
            write(1, OC) -- oc
            write(2, require("OC.Tinu.core.components.json")) -- json
            LDX(require("OC.Tinu.core.processes"))
            X().init(OC, function ()
                write(3, X())
                LDY(require("OC.Tinu.core.fileSystem"))
                write(4, Y())

                write(5, require("OC.Tinu.core.evs"))
                read(5).init(OC, X())

                LDA(require("OC.Tinu.core.app"))
                A().init(X(), function (success, erorr)
                    if not success then
                        erorr(erorr)
                    end
                    Y():init(function(success, err)
                            if not success then
                                print("Init failed:", err)
                                return
                            end
                            local commands = require("OC.Tinu.core.commands")
                            commands.init({oc = OC, process = X(), fs = Y()})
                            write(8, commands)
                            config.disk:read("is_load", function (is_load)
                                if is_load ~= "true" then
                                    config.disk:write("is_load", "true", function(success)
                                        if success then
                                            Y():mkDir("/Tinu", function (success, error)
                                                if success then
                                                    Y():mkDir("/user", function (success, error)
                                                        if success then
                                                            Y():mkDir("/Tinu/programs", function (success, error)
                                                                if success then
                                                                    -- Y():getDirFiles("/Tinu", function (files, dirs)
                                                                    --     print(json.encode(files), json.encode(dirs))
                                                                    -- end, true)
                                                                    local defaultApps = require("OC.Tinu.core.defaultPrograms")
                                                                    local isLoad = 0
                                                                    local installApps = {}
                                                                    for key, value in pairs(defaultApps) do
                                                                        isLoad = isLoad + 1
                                                                        installApps[key] = false
                                                                    end
                                                                    for key, value in pairs(defaultApps) do
                                                                        value(X(), function (success, error)
                                                                            if success then
                                                                                print(key .. " "..error)
                                                                            else
                                                                                print(key.." error installled: "..error)
                                                                            end
                                                                            if not installApps[key] then
                                                                                isLoad = isLoad - 1
                                                                            end
                                                                        end)
                                                                    end
                                                                    while isLoad >= 1 do
                                                                        coroutine.yield()
                                                                    end
                                                                    config.disk:saveToFile("TinuOC")
                                                                    OC.start(X())
                                                                else
                                                                    print("Create /Tinu/programs "..error)
                                                                end
                                                            end, true)
                                                        else
                                                            print("Create /user "..error)
                                                        end
                                                    end, true)
                                                else
                                                    print("Create /Tinu" .. error)
                                                end
                                            end, true)
                                        end
                                    end)
                                else
                                    OC.start(X())
                                    -- X().addProcess("test", function ()
                                    --     print(99)
                                    -- end, function (suc, co)
                                    --     print(suc, co)
                                    -- end)
                                
                                    -- local file = Y():open("test.txt", "w")
                                    -- file:write("test", function (success, errors)
                                    --     if not success then
                                    --         print(errors)
                                    --         return nil
                                    --     end
                                    --     file.close()
                                    --     local file = Y():open("test.txt", "r")
                                    --     file:read(function (value, erorr)
                                    --         print(value, erorr)
                                
                                
                                    --         file:remove(function (succes, erorr)
                                    --             print(succes, erorr)
                                    --             file:read(function (value, erorr)
                                    --             print(value, erorr)
                                    --             end)
                                    --         end)
                                    --     end)
                                    -- end)
                                
                                    -- read(5).mk_event("keypressed", function (e)
                                    --     print(e.key)
                                    -- end)
                                end

                                    local file = Y():open("/test.txt", "w", true)
                                    file:write(
[[
test
test2
linestimor
cerb
]], function (success, erorr)
                                        if not success then
                                            print(erorr)
                                        end
                                        file.close()
                                    end)
local file = Y():open("/test.app", "w", true)
file:write([==[{
    name = "test",
    version = "1.0",
    title = "test",
    code = [[
        print("test")
        ADD_COMMAND("hello", function(shell, args, callback)
            callback(args[1] or "test hello <text>")
        end)
        ADD_COMMAND("help", function(shell, args, callback)
            callback("Test app commands: hello")
        end)
        ADD_COMMAND("hide", function(shell, args, callback)
            callback("Hide terminal")
            TERMINAL_ISVISIBLE(false)
            read(1).devices.GPU:clear()
        end)
        TERMINAL("help", {}, function(text)
            print(text)
        end)
        local s = {}
        ADD_EVENT("keypressed", function(e)
            table.insert(s, e.key)
        end)
        TERMINAL_ISVISIBLE(false)
        while TRUE do
            coroutine.yield()
            CLEAR()
            DTX(200, 150, "TEST", {255, 0, 0}, 1)
            local text = ""
            for index, value in ipairs(s) do
                text = text .. value .. "\n"
            end
            DTX(5, 5, text, {0, 255, 0}, 1)
            SLEEP(0.05)
        end
    ]],
    modules = {"lua5.1"}
}]==], function (success, erorr)
    if not success then
        print(erorr)
    end
    file.close()
end)
                            end)
                    end, config.disk, OC)
                end)
            end)
        end)
    end)
end

OC.start = function (process)
    process.addProcess("start_os", function ()
        LDA(require("OC.Tinu.core.shell"))
        OC.devices.GPU:clear()
        A().run(process)
        write(7, A())
        print("start")
        process.removeProcess("start_os", function (succes, error)
            if not succes then
                print("[OC] error delete start process "..error)
            end
        end)
    end, function (success, erorr)
        if not success then
            print("[OC] error launch start process "..erorr)
        end
    end)
end

OC.update = function(dt)
    OC.devices.CPU:update(dt)
    OC.devices.GPU:update(dt)
    OC.devices.COOLER:update(dt)
    OC.devices.MONITOR:update(dt)
    OC.devices.PSU:update(dt)
    OC.devices.MB:update(dt)
end

OC.draw = function()
    OC.devices.MONITOR:draw()
end

OC.keypressed = function (key)
    if OC.evs then
        OC.evs.predict("keypressed", {key = key})
    end
end

OC.keyreleased = function (key)
    if OC.evs then
        OC.evs.predict("keyreleased", {key = key})
    end
end

return OC
local OC = {
    devices = {},
}

OC.init = function(config)
    config.gpu.driver = "Unakoda"
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

    config.disk:loadFromFile("TinuOC")
    config.cpu:addThread(function ()
        LDA({255, 255, 255})

        LDX("Load Tinu")
        DTX(10, 10, X(), A(), 2)

        write(0, require("OC.Tinu.core.ram"))
        LDA(read(0))

        A().init(OC, function () -- init ram system
            write(1, OC) -- oc
            LDX(require("OC.Tinu.core.processes"))
            X().init(OC, function ()
                write(3, X())
                LDY(require("OC.Tinu.core.fileSystem"))

                write(5, require("OC.Tinu.core.evs"))
                read(5).init(OC)

                write(4, Y())
                Y():init(function(success, err)
                        if not success then
                            print("Init failed:", err)
                            return
                        end
                        config.disk:read("is_load", function (is_load)
                            if is_load ~= "true" then
                                config.disk:write("is_load", "true", function(success)
                                    if success then
                                        print("start")
                                        --config.disk:saveToFile("TinuOC")
                                        --startOS()
                                    end
                                end)
                            else
                                config.gpu:clear()
                                print("start")
                                X().addProcess("test", function ()
                                    print(99)
                                end, function (suc, co)
                                    print(suc, co)
                                end)
                            
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
                                --startOS()
                            
                                read(5).mk_event("keypressed", function (e)
                                    print(e.key)
                                end)
                            end
                        end)
                end, config.disk, OC)
            end)
        end)
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
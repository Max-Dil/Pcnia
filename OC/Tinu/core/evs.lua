local evs = {}
local eventQueue = {}

evs.init = function (OC, process)
    evs.data = {
        keypressed = {},
        keyreleased = {},
    }
    OC.evs = evs

    process.addProcess("evs.lua", function ()
        local speed = 0.035 -- +-30 fps
        if OC.devices.model == "Zero1" then
            speed = 0.5 -- 2 fps
        elseif OC.devices.model == "Ore" or OC.devices.model == "Zero2" or OC.devices.model == "Zero5000" then
            speed = 0.05 -- 20 fps
        end
        -- if OC.devices.model == "Zero5000 PRO MAX" then
        --     speed = 0.01 -- 90fps
        -- end
        LDA({
            ["'"] = '"',
            ["="] = '+',
            ["-"] = '_',
            ["9"] = '(',
            ["0"] = ')',
            ["8"] = '*',
            ["7"] = '&',
            ["6"] = '^',
            ["5"] = '%',
            ["4"] = '$',
            ["3"] = '#',
            ["2"] = '@',
            ["1"] = '!',
            ["`"] = '~',
            [";"] = ':',
            ["["] = "{",
            ["]"] = "}",
            [","] = '<',
            ["."] = '>',
            ["/"] = '?',
        })
        while true do
            SLEEP(speed)
            if #eventQueue > 0 then
                local operation = table.remove(eventQueue, 1)

                if operation then
                    if operation.type == "predict" then
                        local name = operation.name
                        local data = operation.data

                        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                            if A()[data.key] then
                                data.key = A()[data.key]
                            else
                                data.key = string.upper(data.key)
                            end
                        end

                        if evs.data[name] then
                            for _, callback in ipairs(evs.data[name]) do
                                callback(data)
                            end
                        else
                            error("[EVS] no support to event: " .. name, 2)
                        end
                    elseif operation.type == "mk_event" then
                        local name = operation.name
                        local callback = operation.callback

                        if evs.data[name] then
                            table.insert(evs.data[name], callback)
                        else
                            error("[EVS] no support to event: " .. name, 2)
                        end
                    elseif operation.type == "rm_event" then
                        local name = operation.name
                        local callback = operation.callback

                        if evs.data[name] then
                            for index, value in ipairs(evs.data[name]) do
                                if value == callback then
                                    table.remove(evs.data[name], index)
                                    break
                                end
                            end
                        else
                            error("[EVS] no support to event: " .. name, 2)
                        end
                    end
                end
            end
            coroutine.yield()
        end
    end, function (success, error)
        if not success then
            print("[EVS] Error start evs system: "..error)
        end
    end)
end

evs.predict = function (name, data)
    table.insert(eventQueue, {type = "predict", name = name, data = data})
end

evs.mk_event = function (name, callback)
    table.insert(eventQueue, {type = "mk_event", name = name, callback = callback})
end

evs.rm_event = function (name, callback)
    table.insert(eventQueue, {type = "rm_event", name = name, callback = callback})
end

return evs
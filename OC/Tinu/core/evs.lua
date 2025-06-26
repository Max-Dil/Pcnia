local evs = {}

evs.init = function (OC)
    evs.data = {
        keypressed = {},
        keyreleased = {},
    }
    OC.evs = evs
    evs.__addThread = function (...)
        return OC.devices.CPU:addThread(...)
    end

    OC.devices.CPU:addThread(function ()
evs.predict = function (name, data)
    LDY{name = name, data = data}
    LDA(evs)
    if A().data[Y().name] then
        for index, value in ipairs(A().data[name]) do
            LDX{index = index, value = value}
            X().value(Y().data)
        end
    else
        error("[EVS] no support to event: "..Y().name, 2)
    end
end
    end)
end

evs.mk_event = function (name, callback)
    evs.__addThread(function ()
        LDY{name=name, callback=callback}
        LDA(evs)
        if A().data[Y().name] then
            table.insert(A().data[Y().name], Y().callback)
        else
            error("[EVS] no support to event: "..Y().name, 2)
        end
    end)
end

evs.rm_event = function (name, callback)
    evs.__addThread(function ()
        LDY{callback = callback, name = name}
        LDA(evs)
        if A().data[Y().name] then
            for index, value in ipairs(A().data[name]) do
                LDX{index = index, value = value}
                IF(X().value == Y().callback, function ()
                    table.remove(A().data[Y().name], X().index)
                end)
            end
        else
            error("[EVS] no support to event: "..Y().name, 2)
        end
    end)
end

return evs
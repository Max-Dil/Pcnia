local m = {}
function m.init(OC, listener)
    OC.devices.CPU:addThread(function ()
        LDA(read(0))

        local i = 10
        m.TEMP = function()
            local address = nil
            while not address do
                i = ADD(i, 1)
                local find = read(i)
                if not find then
                    address = i
                    break
                end
            end
            return address
        end

        m.FREE = function(addr, count)
            for index = addr, count, 1 do
                if i == index then
                    i = SUB(i, 1)
                end
            end
        end

        write(0, A())
        listener()
    end)
end

return m
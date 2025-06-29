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
            count = count or 1
            for index = addr, addr + count, 1 do
                if i == index then
                    i = SUB(i, 1)
                    for index2 = i, 10, -1 do
                        if not read(index2) then
                            i = SUB(i, 1)
                        else
                            break
                        end
                    end
                end
            end
            free(addr, count)
        end

        write(0, A())
        listener()
    end)
end

return m
local m = {}
function m.init(OC, listener)
    OC.devices.CPU:addThread(function ()
        LDA(read(0))
        A().__write, A().__read = write, read
        A().__free = function(address, count)
            OC.devices.RAM:free(address, count)
        end
        A().__addThread = function(...)
            return OC.devices.CPU:addThread(...)
        end

        function m.TEMP()
            LDX{i = 11, address = NIL, find = NIL} -- start 8 to Tinu.lua
            while not X().address do
                X().find = A().__read(X().i)
                if not X().find then
                    X().address = X().i
                    break
                end
                X().i = ADD(X().i, 1)
            end
            return X().address
        end
        write(0, A())
        listener()
    end)
end

return m
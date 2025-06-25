local function reboot(self)
    CPU:addThread(function ()
        print("[OS] Rebooting system...")

        local envApps = RAM:read(2)
        for appKey, app in pairs(envApps) do
            if app.close then
                app.close()
            end
        end
    
        RAM:clear()
    
        if CPU.cores then
            for core = 1, #CPU.cores, 1 do
                for i = #CPU.cores[core].threads, 1, -1 do
                    local thread = CPU.cores[core].threads[i]
                    if coroutine.status(thread) ~= "dead" then
                        table.remove(CPU.cores[core].threads, i)
                    end
                end
            end
        else
            for i = #CPU.threads, 1, -1 do
                local thread = CPU.threads[i]
                if coroutine.status(thread) ~= "dead" then
                    table.remove(CPU.threads, i)
                end
            end
        end
    
        GPU:clear()
        MONITOR:powerOff()
        MONITOR:powerOn()
    
        print("[OS] Start system...")
        CPU:addThread(function()
            SLEEP(1)
    
            HDD:read("is_load", function(is_load)
                if is_load == "true" then
                    self:startOS()
                else
                    self:installDefaultOS()
                end
            end)
        end)
    end)
end

return reboot
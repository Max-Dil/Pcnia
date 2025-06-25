local shell = {
    version = 1.0,
    __addThread = nil,
}

shell.init = function (OC)
    shell.__addThread = function (...)
        return OC.devices.CPU:addThread(...)
    end
end

shell.run = function ()
    if not shell.__addThread then
        print("[shell] no init")
        return
    end
    shell.__addThread(function ()
        LDA(read(0)) -- ram system control

        
    end)
end

return shell
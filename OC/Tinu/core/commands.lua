local commands = {}

commands.help = function (shell, args, callback)
    shell.__addThread = function ()
        LDY{shell = shell, args = args, callback = callback}
        IF(Y().args[1] == "system", function ()
            callback("Tinu - top OC!!!!!")
        end, function ()
            
        end)
    end
end

return commands
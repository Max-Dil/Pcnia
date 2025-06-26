local commands = {}

commands.help = function (shell, args, callback)
    callback("Commands: help, clear, ver, reboot")
end

commands.clear = function (shell, args, callback)
    if shell.clear then
        shell.clear()
    else
        callback("[ERROR] Shell does not support clearing the console.")
    end
end

commands.ver = function (shell, args, callback)
    callback("Virtual Shell v" .. tostring(shell.version))
end

commands.reboot = function (shell, args, callback)
    if shell.reboot then
        shell.reboot()
    else
        callback("[ERROR] Shell does not support rebooting.")
    end
end

return commands

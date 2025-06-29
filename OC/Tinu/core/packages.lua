return [==[
local packages = {
    ["lua5.1"] = {
        coroutine = {
            yield = coroutine.yield
        },
        print = print,
        pcall = pcall,
        xpcall = xpcall,
        os = os,
        table = table,
        unpack = unpack or table.unpack,
        ipairs = ipairs,
        pairs = pairs,
        next = next,
        math = math,
        string = string,

        setmetatable = setmetatable,
        getmetatable = getmetatable,
        rawequal = rawequal,
        rawget = rawget,
        rawset = rawset,

        select = select,
        type = type,
        tonumber = tonumber,
        tostring = tostring,

        assert = assert,
        error = error,
    },
    ["luajit"] = {
        jit = require("jit"),
        ffi = require("ffi"),
        bit = require("bit"),
    },
    ["json"] = {
        json = read(2),
    },

    ["oc"] = {
        oc = read(1)
    },
    ["ram"] = {
        ram = read(0)
    },
    ["processes"] = {
        processes = {
            list = function(listener)
                read(3).list(listener)
            end,
            addProcess = function(name, func, listener)
                table.insert(PROCESSES, name)
                read(3).addProcess(name, func, listener)
            end,
            removeProcess = function(name, listener)
                for i=1, #PROCESSES, -1 do
                    if PROCESSES[i] == name then
                        table.remove(PROCESSES, i)
                        break
                    end
                end
                read(3).removeProcess(name, listener)
            end,
            findProcessById = function(id, listener)
                read(3).findProcessById(id, listener)
            end,
            getProcessInfo = function(name, listener)
                read(3).getProcessInfo(name, listener)
            end,
            suspendProcess = function(name, listener)
                read(3).suspendProcess(name, listener)
            end,
            resumeProcess = function(name, listener)
                read(3).resumeProcess(name, listener)
            end,
        },
    },
    ["event"] = {
        event = read(5)
    },
    ["commands"] = {
        commands = read(8)
    },
    ["app"] = {
        app = read(9)
    },
    ["fs"] = {
        fs = read(4),
    },
}
]==]
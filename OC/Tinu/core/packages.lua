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
        processes = read(3)
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
}
]==]
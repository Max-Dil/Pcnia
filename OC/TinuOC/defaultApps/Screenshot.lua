local prtApp = {
    name = "Prt Sc",
    version = "1.0",
    main = "main",
    iconText = "Prt",
    iconTextColor = {0, 0, 0},
    system = true,
    backgroundJob = true,
    scripts = {
        main = [[
DTX(MONITOR.resolution.width/2 - (4*14), MONITOR.resolution.height/2, "Please hide app", {255, 255, 255})



while true do
    __DRE(10, MONITOR.resolution.height-30, 20, 20, {255, 255, 0})
    SLEEP(1)
end
]]
    }
}

return prtApp
local function runApp(self, app, appIndex)
    local APP
    if not app.name or not app.main or not app.scripts then
        print("[OS] Error: App is missing required fields")
        return
    end
    
    if not app.scripts[app.main] then
        print("[OS] Error: App is missing launch main script")
        return
    end
    
    local ram_x, ram_y = 50, 100
    
    local searchRam
    searchRam = function(x, y)
        local is_search = false
        for i = ram_x, ram_y do
            if RAM:read(i) ~= 0 then
                is_search = true
            end
        end
        if is_search then
            ram_x, ram_y = ram_x + 50, ram_y + 50
            searchRam(ram_x, ram_y)
        end
    end
    searchRam(ram_x, ram_y)
    
    local function restrictedRead(address)
        if ram_x + address > ram_y then
            return "Limit App Ram (50)"
        end
        return RAM:read(ram_x + address)
    end
    
    local function restrictedWrite(address, data)
        if ram_x + address > ram_y then
            return "Limit App Ram (50)"
        end
        RAM:write(ram_x + address, data)
    end
    
    local __events = {
        mousereleased = {},
        keypressed = {},
        mousepressed = {},
        mousemoved = {}
    }
    
    local function handleMouseReleased(x, y, button)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        if x > MONITOR.resolution.width - 20 and x < MONITOR.resolution.width - 10 and y < 30 and y > 10 then
            APP.close(ram_x, ram_y)
        end
        if x > MONITOR.resolution.width - 35 and x < MONITOR.resolution.width - 25 and y < 20 and y > 10 then
            APP.hide()
        end
        for i = 1, #__events.mousereleased do
            __events.mousereleased[i](x, y, button)
        end
    end
    
    local function handleMouseMoved(x, y, dx, dy)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        for i = 1, #__events.mousemoved do
            __events.mousemoved[i](x, y, dx, dy)
        end
    end
    
    local function handleMousePressed(x, y, button)
        local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
        local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
        local scale = math.min(scaleX, scaleY)
        x, y = x / scale, y / scale
        for i = 1, #__events.mousepressed do
            __events.mousepressed[i](x, y, button)
        end
    end
    
    local function handleKeypressed(key, scancode, isrepeat)
        for i = 1, #__events.keypressed do
            __events.keypressed[i](key, scancode, isrepeat)
        end
    end
    
    local function addEventHandler(name, listener)
        table.insert(__events[name], listener)
    end

    local removeHandler = function (name, listener)
        for i = 1, #__events[name], 1 do
            if __events[name][i] == listener then
                table.remove(__events[name], i)
                break
            end
        end
    end
    
    local runScript = function (name)
        self:runAppScript(name, app)
    end
    
    APP = {
        __events = __events,
        threads = {},
        name = app.name,
        app = app,
        version = app.version,
        close = function()
            local count = ram_y - ram_x
            RAM:free(ram_x, count + 1)
            for i = 1, #APP.threads do
                local s = CPU:searchThread(APP.threads[i])
                if s then
                    CPU:removeThread(s)
                end
            end
            CPU:addThread(function ()
                GPU:clear()
                SLEEP(0.1)
                GPU:clear()
                APP = nil
                local envApps = RAM:read(2)
                if envApps[app.name .. ":" .. app.version] then
                    envApps[app.name .. ":" .. app.version] = nil
                end
                RAM:write(2, envApps)
                local interface = RAM:read(1)
                interface()
            end)
        end,
        hide = function (isNotMenu)
            OC.mousereleased = nil
            OC.keypressed = nil
            OC.mousepressed = nil
            OC.mousemoved = nil
            for i = 1, #APP.threads do
                local s = CPU:searchThread(APP.threads[i])
                if s then
                    CPU:removeThread(s)
                end
            end
            APP.frame_buffer = json.encode(GPU.frame_buffer)
            GPU:clear()
            if not isNotMenu then
                local interface = RAM:read(1)
                interface()
            end
            APP.isVisible = false
            local envApps = RAM:read(2)
            envApps[app.name .. ":" .. app.version] = APP
            RAM:write(2, envApps)
        end,
        show = function ()
            OC.mousereleased = handleMouseReleased
            OC.keypressed = handleKeypressed
            OC.mousepressed = handleMousePressed
            OC.mousemoved = handleMouseMoved
            GPU.frame_buffer = json.decode(APP.frame_buffer)
            APP.frame_buffer = nil
            for i = 1, #APP.threads do
                local success, co = CPU:addThread(function ()end)
                if success then
                    local s, core = CPU:searchThread(co)
                    if core then
                        CPU.cores[core].threads[s] = APP.threads[i]
                    elseif s then
                        CPU.threads[s] = APP.threads[i]
                    else
                        print("[OS] Error: App is missing resume processes")
                    end
                else
                    print("[OS] Error: App is missing resume processes")
                end
            end
            local envApps = RAM:read(2)
            envApps[app.name .. ":" .. app.version] = APP
            RAM:write(2, envApps)
            APP.isVisible = true
        end,
        isVisible = true
    }
    APP.env = {
        addEvent = addEventHandler,
        removeEvent = removeHandler,
        read = restrictedRead,
        write = restrictedWrite,
        json = require("json"),
        runScript = runScript,
    }
    
    CPU:addThread(function()
        GPU:clear()
        LDA(app.name)
        DTX(MONITOR.resolution.width/2 - (#A() * 6), 10, A(), {255, 255, 255}, 2)
        DRE(MONITOR.resolution.width - 20, 10, 10, 10, {255, 0, 0})
        DRE(MONITOR.resolution.width - 35, 10, 10, 10, {0, 100, 255})
    end)
    
    OC.mousereleased = handleMouseReleased
    OC.keypressed = handleKeypressed
    OC.mousepressed = handleMousePressed
    OC.mousemoved = handleMouseMoved
    
    local envApps = RAM:read(2)
    if envApps[app.name .. ":" .. app.version] then
        envApps[app.name .. ":" .. app.version].close()
    end
    envApps[app.name .. ":" .. app.version] = APP
    RAM:write(2, envApps)

    self:runAppScript(app.main, app)

    
    print("[OS] Successfully launched App: " .. app.name .. ":" .. app.version)
end

return runApp
_G.json = require("json")

OC = {
    path = ...,
    version = "0.1",
    name = "TinuOS",
    is_installing = false,
    logs = {}
}

--[[ ----- Ram --------
-1 | файловая система
0 | запущенные приложений
1 | интерфейс ос
2 | окружения запущенный приложений
]]

--[[
is_load   | Загрузочный сектор (MBR)
/trash/ | Корзина

Dekstop | рабочий стол
Documents | документы
Tinu | файлы системы
User | файлы пользователя
User/AppData | файлы приложений
]]

--[[
Архитектура приложения:
name | имя программы
version | версия
icon | таблица цветов иконки 32 на 32
iconText | текст иконки
iconTextColor | цвет текста на иконке
system | системное приложение
company | компания
scripts {} | скрипты
main | оснвоной скрипт
]]

function OC:init(data)
    love.graphics.setDefaultFilter( 'nearest', 'nearest', 1 )
    OC.logs = {}
    local origPrint = print
    print = function (...)
        origPrint(...)
        pcall(function (...)
            table.insert(OC.logs,json.encode({...}))
        end,...)
    end
    CPU = data.processor
    data.processor:init()
    MB = data.mother:init(data.processor)
    CPU:setMotherboard(MB)
    RAM = data.ram:init(MB)
    COOLER = data.cooler:init(data.processor, MB)
    MB:attachCooler(COOLER)
    PSU = data.blockEnergy:init(MB)
    data.gpu.driver = "Unakoda"
    GPU = data.gpu:init(data.processor)
    MONITOR = data.monitor:init(GPU)
    data.processor:setGPU(GPU)
    MB.gpu = GPU
    MB.monitor = MONITOR
    PSU.monitor = MONITOR
    HDD = data.disk:init(MB)
    MB:attachStorage(HDD)
    MB:addInterrupt("TIMER", {interval = 1})

    GPU:setResolution(MONITOR.resolution.width, MONITOR.resolution.height)

    CPU.updateComponents = function (dt)
        RAM:update(dt)
        HDD:update(dt)
    end

    CPU:addThread(function ()
        LDA({255, 255, 255})

        LDX("Load TinuOC")
        DTX(10, 10, X(), A(), 2)

        LDX("by Stimor")
        DTX(MONITOR.resolution.width - 70 , MONITOR.resolution.height - 10, X(), A(), 1)

        LDX("Tiny OC corparation")
        LDA({255, 0, 255})
        DTX(MONITOR.resolution.width/2 - (6 * #X()), MONITOR.resolution.height/2 - 10, X(), A(), 2)
    end)

    OC.installApp = require("OC.TinuOC.Programs.install")
    OC.uninstallApp = require("OC.TinuOC.Programs.uninstall")
    OC.loadApp = require("OC.TinuOC.Programs.load")
    OC.runAppScript = require("OC.TinuOC.Programs.runScript")
    OC.runApp = require("OC.TinuOC.Programs.run")
    OC.updateAppsSearch = require("OC.TinuOC.Programs.updates")

    OC.reboot = require("OC.TinuOC.reboot")

    OC.installDefaultOS = require("OC.TinuOC.install")

    -- HDD:addEventListener("write", function(hdd, address)
    --     print(string.format("[HDD] Write: addr=" .. address .. ", used=%.2fMB/%.2fMB",
    --         hdd.usedSpace/1024, hdd.effectiveCapacity))
    -- end)

    -- HDD:addEventListener("read", function(hdd, address)
    --     print(string.format("[HDD] Read: addr=" .. address))
    -- end)

    HDD:loadFromFile("TinuOC_Typyka")
    FILE_SYSTEM = require("OC.TinuOC.fileSystem")
    CPU:addThread(function ()
        FILE_SYSTEM:init(function(success, err)
            if not success then
                print("Init failed:", err)
                return
            end

            HDD:read("is_load", function (is_load)
                if is_load ~= "true" then
                    HDD:write("is_load", "true", function(success)
                        if success then
                            HDD:saveToFile("TinuOC_Typyka")
                            self:startOS()
                        end
                    end)
                else
                    self:startOS()
                end
            end)
        end)
    end)
end

function OC:update(dt)
    CPU:update(dt)
    GPU:update(dt)
    COOLER:update(dt)
    MONITOR:update(dt)
    PSU:update(dt)
    MB:update(dt)
end

function OC:draw()
    MONITOR:draw()
end

function OC:startOS()
    CPU:addThread(function ()
        local init = function (kernel)
            local file = FILE_SYSTEM:open("Dekstop/test.txt", "w")
            file:write("100", function ()end)
    
            CPU:addThread(function ()
                write(0, {}) -- apps
                RAM:write(2, {}) -- env apps
                write(1, function ()
                    GPU:clear()
            
                    LDA({255, 255, 255})
                    LDX(kernel.name .. " v" .. kernel.version)
                    DTX(10, 10, X(), A(), 2)
            
                    local iconSize = 32
                    local margin = 20
                    local textHeight = 20
                    local startX = margin
                    local startY = margin + 40
                    local itemsPerRow = math.floor((MONITOR.resolution.width - margin * 2) / (iconSize + margin))
            
                    local file = FILE_SYSTEM:getDirFiles("Dekstop", function (files)
                        local i = 0
                        local appPositions = {}
                        local filesPositions = {}
                        
                        for path, value in pairs(files) do
                            local file = FILE_SYSTEM:open("Dekstop/"..path, "r")
                            i = i + 1
                            file:read(function (data)
                                if data then
                                    local row = math.floor((i-1) / itemsPerRow)
                                    local col = (i-1) % itemsPerRow
                                    local x = startX + col * (iconSize + margin)
                                    local y = startY + row * (iconSize + margin + textHeight)
            
                                    if file.fileExt == "app" then
                                        local fileApp = FILE_SYSTEM:open(data .. "/app.json", "r")
                                        fileApp:read(function (appJson)
                                            local app = json.decode(appJson)
            
                                            if app then
                                                local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                                                appPositions[i] = {
                                                    x = x,
                                                    y = y,
                                                    width = iconSize,
                                                    height = iconSize,
                                                    appPath = data,
                                                    appData = app,
                                                    appIndex = appIndex
                                                }
            
                                                if app.icon then
                                                    DRM(x, y, app.icon)
                                                else
                                                    LDA({150, 150, 150})
                                                    DRE(x, y, iconSize, iconSize, A())
                                                end
            
                                                local envApps = RAM:read(2)
                                                local appKey = app.name .. ":" .. app.version
                                                if envApps[appKey] then
                                                    LDA({0, 255, 0})
                                                    DRE(x + iconSize - 5, y + iconSize - 5, 5, 5, A())
                                                end
            
                                                if app.iconTextColor then
                                                    LDA(app.iconTextColor)
                                                else
                                                    LDA({0,0,0})
                                                end
                                                if app.system then
                                                    LDX("SYS")
                                                    DTX(x + 1, y + iconSize - 8, X(), A(), 1)
                                                end
                                                if app.iconText then
                                                    LDX(app.iconText)
                                                else
                                                    LDX("Icon")
                                                end
                                                DTX(x + iconSize/2 - (#X() * 3), y + iconSize/2 - 3, X(), A(), 1)
            
                                                LDA({255, 255, 255})
                                                LDX(app.name)
                                                DTX(x + iconSize/2 - (#X() * 3), y + iconSize + 5, X(), A(), 1)
                                            end
                                        end)
                                    else
                                        table.insert(filesPositions, {
                                            x = x,
                                            y = y,
                                            width = iconSize,
                                            height = iconSize,
                                            data = data,
                                            ext = file.fileExt,
                                            path = file.path,
                                            name = file.fileName
                                        })

                                        LDA({150, 150, 150})
                                        DRE(x, y, iconSize, iconSize, A())
            
                                        LDA({0,0,0})
                                        LDX(file.fileExt)
                                        DTX(x + iconSize/2 - (#X() * 3), y + iconSize/2 - 3, X(), A(), 1)
            
                                        LDA({255, 255, 255})
                                        LDX(file.fileName)
                                        DTX(x + iconSize/2 - (#X() * 3), y + iconSize + 5, X(), A(), 1)
                                    end
                                end
                            end)
                        end

                        local function split(str, delimiter)
                            local result = {}
                            for part in str:gmatch("[^" .. delimiter .. "]+") do
                                table.insert(result, part)
                            end
                            return result
                        end
            
                        OC.mousereleased = function (x, y)
                            local scaleX = love.graphics.getWidth() / MONITOR.resolution.width
                            local scaleY = love.graphics.getHeight() / MONITOR.resolution.height
                            local scale = math.min(scaleX, scaleY)
                            x, y = x / scale, y / scale
    
                            for _, app in pairs(appPositions) do
                                if x >= app.x and x <= app.x + app.width and
                                   y >= app.y and y <= app.y + app.height then
                                    
                                    local envApps = RAM:read(2)
                                    local appKey = app.appData.name .. ":" .. app.appData.version
                                    
                                    if envApps[appKey] then
                                        envApps[appKey].show()
                                    else
                                        OC:loadApp(app.appIndex)
                                    end
                                    return
                                end
                            end

                            for _, file in pairs(filesPositions) do
                                if x >= file.x and x <= file.x + file.width and
                                   y >= file.y and y <= file.y + file.height then
                                    
                                    if file.ext == "txt" then
                                        local fileApp = FILE_SYSTEM:open("User/AppData/app_notepad/app.json", "r")
                                        fileApp:read(function (appJson)
                                            local app = json.decode(appJson)
                                            
                                            if app then
                                                local appIndex = "app_" .. app.name:lower():gsub("[^%w]", "_")
                                                local envApps = RAM:read(2)
                                
                                                local appKey = app.name .. ":" .. app.version
                                                                    
                                                if envApps[appKey] then
                                                    envApps[appKey].show()
                                
                                                    local APP = envApps[app.name .. ":" .. app.version]
                                                    local fileName = split(file.path, "/")
                                                    for i=1 , #fileName, 1 do
                                                        if fileName[i] == "files" then
                                                            table.remove(fileName, i)
                                                        else
                                                            break
                                                        end
                                                    end
                                                    fileName = table.concat(fileName, "/")
                                                    local file = FILE_SYSTEM:open(fileName, "r")
                                                    file:read(function(text)
                                                        APP.loadFilePath({
                                                            path = file.path,
                                                            name = file.name,
                                                            data = text
                                                        })
                                                    end)
                                                else
                                                    OC:loadApp(appIndex, function()
                                                        ::searchAPP::
                                                        envApps = RAM:read(2)
                                                        if not envApps[app.name .. ":" .. app.version] then
                                                            SLEEP(1)
                                                            goto searchAPP
                                                        end
                                
                                                        ::searchLoadFunc::
                                                        local APP = envApps[app.name .. ":" .. app.version]
                                                        if not APP.loadFilePath then
                                                            SLEEP(1)
                                                            goto searchLoadFunc
                                                        end
                                                        local fileName = split(file.path, "/")
                                                        for i=1 , #fileName, 1 do
                                                            if fileName[i] == "files" then
                                                                table.remove(fileName, i)
                                                            else
                                                                break
                                                            end
                                                        end
                                                        fileName = table.concat(fileName, "/")
                                                        local file = FILE_SYSTEM:open(fileName, "r")
                                                        file:read(function(text)
                                                            APP.loadFilePath({
                                                                path = file.path,
                                                                name = file.name,
                                                                data = text
                                                            })
                                                        end)
                                                    end)
                                                end
                                            end
                                        end)
                                        return nil
                                    end
                                    return
                                end
                            end
                        end
                    end)
                end)
                read(1)()
            end)
        end
    
        local file = FILE_SYSTEM:open("Tinu/core.json", "r")
        file:read(function (value, err)
            if not value then
                print("[OS] Error: Invalid kernel data ", err)
                self:installDefaultOS()
                return
            end
    
            local kernel = json.decode(value)
            if kernel then
                init(kernel)
            end
        end)
    end)
end

return OC
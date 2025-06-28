local m = {}
local requestQueue = {}

local getProcessStorage
local updateProcessStorage

function m.init(OC, listener)
    OC.devices.CPU:addThread(function ()
        m.__addThread = function(...)
            return OC.devices.CPU:addThread(...)
        end
        m.__searchThread = function(co)
            return OC.devices.CPU:searchThread(co)
        end
        m.__removeThread = function(id)
            return OC.devices.CPU:removeThread(id)
        end

        local load = true
        m.__addThread(function ()
            getProcessStorage = function(listener)
                LDY({listener = listener})
                LDA(read(6))
                Y().listener(A())
            end
            load = false
        end)
        while load do coroutine.yield() end

        load = true
        m.__addThread(function ()
            updateProcessStorage = function(storage, listener)
                LDY({storage = storage, listener = listener})
                write(6, Y().storage)
                Y().listener()
            end
            load = false
        end)
        while load do coroutine.yield() end

        LDA(read(6))
        IF(not A(), function ()
            write(6, {
                processes = {},
                counter = 0
            })
            listener()
        end, function ()
            listener()
        end)

        local speed = 0.035 -- +-30 fps
        if OC.devices.model == "Zero1" then
            speed = 0.5 -- 2 fps
        elseif OC.devices.model == "Ore" or OC.devices.model == "Zero2" or OC.devices.model == "Zero5000" then
            speed = 0.05 -- 20 fps
        end
        -- if OC.devices.model == "Zero5000 PRO MAX" then
        --     speed = 0.01 -- 90fps
        -- end
        while true do
            SLEEP(speed)
            local request = table.remove(requestQueue, 1)
            if request then
                if request.type == "list" then
                    LDY({listener = request.listener})
                    getProcessStorage(function (storage)
                        LDA(storage)
                        LDX({})
                        for name, proc in pairs(A().processes) do
                            table.insert(X(), {
                                name = name,
                                id = proc.id,
                                thread = proc.thread,
                                status = proc.status,
                                func = proc.func,
                                args = proc.args
                            })
                        end
                        Y().listener(X())
                    end)

                elseif request.type == "addProcess" then
                    LDY({name = request.name, func = request.func, listener = request.listener}) -- args
                    getProcessStorage(function(storage)
                        LDA(storage)
                        if A().processes[Y().name] then
                            Y().listener(FALSE, "Process with this name already exists")
                            return NIL
                        end

                        A().counter = A().counter + 1
                        LDX({m.__addThread(Y().func)})

                        if not X()[1] then
                            Y().listener(FALSE, X()[2])
                            return NIL
                        end

                        A().processes[Y().name] = {
                            id = A().counter,
                            thread = X()[2],
                            status = "running",
                            name = Y().name,
                            func = Y().func
                        }

                        updateProcessStorage(A(), function ()
                            Y().listener(TRUE, X()[2])
                        end)
                    end)

                elseif request.type == "removeProcess" then
                    LDY({name = request.name, listener = request.listener})
                    getProcessStorage(function(storage)
                        LDA(storage)
                        if not A().processes[Y().name] then
                            Y().listener(FALSE, "Process not found")
                            return NIL
                        end

                        LDX({m.__searchThread(A().processes[Y().name].thread)})
                        if X()[1] then
                            m.__removeThread(X()[1])
                        end

                        A().processes[Y().name] = NIL
                        updateProcessStorage(A(), function ()
                            Y().listener(TRUE)
                        end)
                    end)

                elseif request.type == "findProcessById" then
                    LDY({id = request.id, listener = request.listener})
                    getProcessStorage(function(storage)
                        LDA(storage)
                        for name, proc in pairs(A().processes) do
                            LDX({name = name, proc = proc})
                            if X().proc.id == Y().id then
                                Y().listener(X().proc)
                                return NIL
                            end
                        end
                        Y().listener(NIL)
                    end)
                
                elseif request.type == "getProcessInfo" then
                    LDY({name = request.name, listener = request.listener})
                    getProcessStorage(function(storage)
                        LDA(storage)
                        if not A().processes[Y().name] then
                            Y().listener(NIL)
                            return NIL
                        end
                        Y().listener(A().processes[Y().name])
                    end)

                elseif request.type == "suspendProcess" then
                    LDY({name = request.name, listener = request.listener})
                    getProcessStorage(function(storage)
                        LDA(storage)
                        if not A().processes[Y().name] then
                            Y().listener(FALSE, "Process not found")
                            return NIL
                        end

                        local proc = A().processes[Y().name]
                        if proc.status ~= "running" then
                            Y().listener(FALSE, "Process is not running")
                            return NIL
                        end

                        local threadId = m.__searchThread(proc.thread)
                        if not threadId then
                            Y().listener(FALSE, "Thread not found in CPU")
                            proc.status = "stopped"
                            proc.thread = nil
                            updateProcessStorage(A(), function() end)
                            return NIL
                        end

                        if not m.__removeThread(threadId) then
                            Y().listener(FALSE, "Failed to remove thread")
                            return NIL
                        end

                        proc.status = "suspended"
                        proc.thread = NIL

                        updateProcessStorage(A(), function ()
                            Y().listener(TRUE)
                        end)
                    end)

                elseif request.type == "resumeProcess" then
                    LDY({name = request.name, listener = request.listener})
                    getProcessStorage(function(storage)
                        LDA(storage)
                        if not A().processes[Y().name] then
                            Y().listener(FALSE, "Process not found")
                            return NIL
                        end

                        LDX(A().processes[Y().name])
                        if X().status ~= "suspended" then
                            Y().listener(FALSE, "Process is not suspended")
                            return NIL
                        end
                        
                        local original_args = Y()
                        LDY({m.__addThread(X().func)})
                        
                        if not Y()[1] then
                            original_args.listener(FALSE, Y()[2])
                            return NIL
                        end

                        X().thread = Y()[2]
                        X().status = "running"

                        updateProcessStorage(A(), function ()
                            original_args.listener(TRUE)
                        end)
                    end)
                end
            end
            coroutine.yield()
        end
    end)
end

--==============================================================================--
--==============================================================================--

-- получение списка процессов
function m.list(listener)
    table.insert(requestQueue, {
        type = "list",
        listener = listener or function() end
    })
end

-- создание процесса
function m.addProcess(name, func, listener)
    table.insert(requestQueue, {
        type = "addProcess",
        name = name,
        func = func,
        listener = listener or function() end
    })
end

-- удаление процесса
function m.removeProcess(name, listener)
    table.insert(requestQueue, {
        type = "removeProcess",
        name = name,
        listener = listener or function() end
    })
end

-- поиск процесса в базе по id
function m.findProcessById(id, listener)
    table.insert(requestQueue, {
        type = "findProcessById",
        id = id,
        listener = listener or function() end
    })
end

-- получение информации о процессе
function m.getProcessInfo(name, listener)
    table.insert(requestQueue, {
        type = "getProcessInfo",
        name = name,
        listener = listener or function() end
    })
end

-- приостановка процесса
function m.suspendProcess(name, listener)
    table.insert(requestQueue, {
        type = "suspendProcess",
        name = name,
        listener = listener or function() end
    })
end

-- возобновление процесса
function m.resumeProcess(name, listener)
    table.insert(requestQueue, {
        type = "resumeProcess",
        name = name,
        listener = listener or function() end
    })
end

return m
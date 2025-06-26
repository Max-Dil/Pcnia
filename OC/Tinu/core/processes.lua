local m = {}

-- инициализациЯ
function m.init(OC, listener)
    OC.devices.CPU:addThread(function ()
        m.__addThread = function(...)
            return OC.devices.CPU:addThread(...)
        end
        m.__searchThread = function(co)
            return OC.devices.CPU:searchThread(co) -- id
        end
        m.__removeThread = function(id)
            return OC.devices.CPU:removeThread(id)
        end

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
    end)
end

-- получение базы данных процессов
local function getProcessStorage(listener)
    m.__addThread(function ()
        LDY({listener = listener})
        LDA(read(6))
        Y().listener(A())
    end)
end

-- обновление базы данных процессов
local function updateProcessStorage(storage, listener)
    m.__addThread(function ()
        LDY({storage = storage, listener = listener})
        write(6, Y().storage)
        Y().listener()
    end)
end

-- полученеи писка процессов
function m.list(listener)
    m.__addThread(function ()
        LDY({listener = listener}) -- args
        LDA(getProcessStorage(function ()
            LDX({}) -- result
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
        end)) -- storage
    end)
end

-- создание процесса
function m.addProcess(name, func, listener)
    m.__addThread(function ()
        LDY({name = name, func = func, listener = listener}) -- args
        getProcessStorage(function(storage)
            LDA(storage)-- storage
            if A().processes[Y().name] then
                Y().listener(FALSE, "Process with this name already exists")
                return NIL
            end

            A().counter = A().counter + 1

            LDX({m.__addThread(Y().func)}) -- success, co

            if not X()[1] then
                Y().listener(FALSE, X()[2])
                return NIL
            end

            A().processes[Y().name] = {
                id = A().counter,
                thread = X()[2],
                status = "running",
                name = Y().name,
                func = Y().func,
            }

            updateProcessStorage(A(), function ()
                Y().listener(TRUE, X()[2])
            end)
        end)
    end)
end

-- удаление процесса
function m.removeProcess(name, listener)
    m.__addThread(function ()
        LDY({name = name, listener = listener}) -- args
        getProcessStorage(function(storage)
            LDA(storage)-- storage
            if not A().processes[Y().name] then
                Y().listener(FALSE, "Process not found")
                return NIL
            end

            LDX(m.__searchThread(A().processes[Y().name].thread)) -- threadId
            if X() then
                m.__removeThread(X())
            end

            A().processes[Y().name] = NIL
            updateProcessStorage(A(), function ()
                Y().listener(TRUE)
            end) 
        end)
    end)
end

-- поиск процесса в базе по id
function m.findProcessById(id, listener)
    m.__addThread(function ()
        LDY({id = id, listener = listener}) -- args
        getProcessStorage(function(storage)
            LDA(storage)-- storage
            for name, proc in pairs(A().processes) do
                LDX({name = name, proc = proc})
                if X().proc.id == Y().id then
                    Y().listener(X().proc)
                    return NIL
                end
            end
            Y().listener(NIL)
        end)
    end)
end

-- получение информации об процессе
function m.getProcessInfo(name, listener)
    m.__addThread(function ()
        LDY({name = name, listener = listener}) -- args
        getProcessStorage(function(storage)
            LDA(storage)-- storage
            if not A().processes[Y().name] then
                Y().listener(NIL)
                return NIL
            end
            Y().listener(A().processes[Y().name])
        end)
    end)
end

-- приостанвока процесса
function m.suspendProcess(name, listener)
    m.__addThread(function ()
        LDY({name = name, listener = listener})
        getProcessStorage(function(storage)
            LDA(storage)-- storage
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
                return NIL
            end

            if not m.__removeThread(threadId) then
                Y().listener(FALSE, "Failed to remove thread")
                return NIL
            end

            proc.status = "suspended"
            proc.thread = NIL

            updateProcessStorage(A(), function ()
                listener(TRUE)
            end)
        end)
    end)
end

-- возообновлкение процесса
function m.resumeProcess(name, listener)
    m.__addThread(function ()
        LDY({name = name, listener = listener})
        getProcessStorage(function(storage)
            LDA(storage)-- storage
            if not A().processes[Y().name] then
                Y().listener(FALSE, "Process not found")
                return NIL
            end

            LDX(A().processes[Y().name])
            if X().status ~= "suspended" then
                Y().listener(FALSE, "Process is not suspended")
                return NIL
            end

            LDY({m.__addThread(X().func)})
            if not Y()[1] then
                LDY(listener)
                Y()(FALSE)
                return NIL
            end

            X().thread = Y()[2]
            X().status = "running"

            updateProcessStorage(A(), function ()
                LDY(listener)
                Y()(TRUE)
            end)
        end)
    end)
end

return m
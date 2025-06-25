local json = require("json")
local HDD

local temp = {}
local fileSystem
fileSystem = {
    version = "1.0",
    getTemp = function(self, listener)
        fileSystem.__addThread(function ()
            LDY{listener = listener}
            LDA(read(0))
            LDX(read(2))
            temp = X() == 0 and temp or X()
            Y().listener(temp)
        end)
    end,
    saveTemp = function(self, listener)
        fileSystem.__addThread(function ()
            LDY{listener = listener}
            LDA(read(0))
            write(2, temp)
            Y().listener()
        end)
    end,
}

local function split(str, delimiter)
    local result = {}
    for part in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

function fileSystem:init(callback, disk, oc)
    oc.devices.CPU:addThread(function ()
        LDY{callback = callback, disk = disk, oc = oc}

        fileSystem.__addThread = function(...)
            return Y().oc.devices.CPU:addThread(...)
        end
        HDD = Y().disk
        LDA(read(4))
        A():saveTemp(function ()
            HDD:read("trash", function(backet)
                LDX(backet)
                if X() == "" then
                    A():mkDir('trash', function(success)
                        LDX(success)
                        if not X() then
                            Y().callback(false, "Failed to create backet folder")
                            return
                        end
                        print("[fileSystem] created backet folder")
                        HDD:read("files", function(files)
                            LDX(files)
                            if X() == "" then
                                A():mkDir('files', function(success)
                                    LDX(success)
                                    if not X() then
                                        Y().callback(false, "Failed to create files folder")
                                        return
                                    end
                                    print("[fileSystem] created files folder")
                                    Y().callback(TRUE)
                                end, true)
                            else
                                Y().callback(TRUE)
                            end
                        end)
                    end, true)
                else
                    Y().callback(TRUE)
                end
            end) -- n
        end)
    end)
end

function fileSystem:open(path, mode, absolute)
    if not absolute then
        path = "files/" .. path
    end
    mode = mode or "w"
    local parts = split(path, "/")
    local fileName = parts[#parts]
    table.remove(parts, #parts)
    local folderPath = table.concat(parts, "/")
    local fileExt = split(fileName, ".")[2] or ""
    --print(path, fileName, folderPath, fileExt)

    local file
    file = {
        path = path,
        folderPath = folderPath,
        fileName = fileName,
        fileExt = fileExt,
        mode = mode,
        closed = false,
        read = function(self, callback)
            fileSystem.__addThread(function ()
                LDY{callback = callback, self = self}
                if Y().self.closed then
                    Y().callback(NIL, "File is closed")
                    return
                end
                if Y().self.mode ~= "r" then
                    Y().callback(NIL, "Permission denied for read: " .. Y().self.path)
                    return
                end

                LDA(read(4))
                A():getTemp(function (storage)
                    LDX(storage)
                    if X()[Y().self.path] then
                        Y().callback(X()[Y().self.path])
                        return
                    end
                    local function findFile(files)
                        if files[Y().self.fileName] then
                            X()[Y().self.path] = files[Y().self.fileName]
                            A():saveTemp(function ()
                                Y().callback(files[Y().self.fileName])
                            end)
                            return TRUE
                        end
                        return FALSE
                    end
                    if X()[Y().self.folderPath] then
                        if findFile(X()[Y().self.folderPath]) then
                            return
                        end
                    end
                    HDD:read(Y().self.folderPath, function(data)
                        if data == "" then
                            Y().callback(NIL, "Folder not found: " .. Y().self.folderPath)
                            return
                        end
                        local success, files = pcall(json.decode, data)
                        if not success then
                            Y().callback(NIL, "Failed to parse folder data: " .. Y().self.folderPath)
                            return
                        end
                        X()[Y().self.folderPath] = files
                        if not findFile(files) then
                            Y().callback(NIL, "File not found: " .. Y().self.fileName)
                        end
                        A():saveTemp(function() end)
                    end)
                end)
            end)
        end,
        write = function(self, data, callback)
            fileSystem.__addThread(function ()
                LDY{self = self, callback = callback, data = data}
                if Y().self.closed then
                    Y().callback(FALSE, "File is closed")
                    return
                end
                if Y().self.mode ~= "w" then
                    Y().callback(FALSE, "Permission denied for write: " .. Y().self.path)
                    return
                end

                LDA(read(4))
                A():getTemp(function (storage)
                    LDX(storage)
                    X()[Y().self.path] = Y().data
                    local function updateFiles(files)
                        files = files or {}
                        files[Y().self.fileName] = Y().data
                        X()[Y().self.folderPath] = files
                        A():saveTemp(function ()
                            HDD:write(Y().self.folderPath, json.encode(files), function(success)
                                Y().callback(success, success and NIL or "Failed to write to HDD")
                            end)
                        end)
                    end
                    if X()[Y().self.folderPath] then
                        updateFiles(X()[Y().self.folderPath])
                        return
                    end
                    HDD:read(Y().self.folderPath, function(hddData)
                        local files = {}
                        if hddData ~= "" then
                            local success, decoded = pcall(json.decode, hddData)
                            if success then
                                files = decoded
                            end
                        end
                        updateFiles(files)
                    end)
                end)
            end)
        end,
        remove = function(self, callback, isTrash)
            fileSystem.__addThread(function ()
                LDY{self = self, callback = callback, isTrash = isTrash}

                if Y().self.closed then
                    Y().callback(false, "File is closed")
                    return
                end

                LDA(read(4))
                HDD:read(Y().self.folderPath, function(data)
                    if data == "" then
                        Y().callback(FALSE, "Folder not found: " .. Y().self.folderPath)
                        return
                    end
                    local success, files = pcall(json.decode, data)
                    if not success then
                        Y().callback(FALSE, "Failed to parse folder data")
                        return
                    end
                    if not files[Y().self.fileName] then
                        Y().callback(FALSE, "File not found: " .. Y().self.fileName)
                        return
                    end
                    local oldValue = files[Y().self.fileName]
                    files[Y().self.fileName] = NIL
                    HDD:write(Y().self.folderPath, json.encode(files), function(success)
                        if success then
                            A():getTemp(function (temp)
                                LDX(temp)
                                X()[Y().self.path] = NIL
                                if X()[Y().self.folderPath] then
                                    X()[Y().self.folderPath][Y().self.fileName] = NIL
                                end
                                A():saveTemp(function ()
                                    HDD.usedSpace = (HDD.usedSpace or 0) - #data
                                    if not Y().isTrash then
                                        HDD:read("trash", function (Trashfiles)
                                            LDX(Trashfiles)
                                            LDX(json.decode(X()))
                                            X()[Y().self.fileName] = oldValue
                                            HDD:write("trash", json.encode(X()), function (success)
                                                LDX(success)
                                                if not X() then
                                                    print("[fileSystem] Failed move file in trush")
                                                end
                                            end)
                                        end)
                                    end
                                end)
                            end)
                        end
                        Y().callback(success, success and NIL or "Failed to remove file")
                    end)
                end)
            end)
        end,
        close = function()
            file.closed = true
        end
    }
    return file
end

function fileSystem:getDirFiles(path, callback, absolute)
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback, absolute = absolute}
        if not Y().absolute then
            Y().path = "files/" .. Y().path
        end

        HDD:read(Y().path, function(filesData)
            local result = {
                files = {},
                directories = {}
            }

            if filesData ~= "" then
                local success, files = pcall(json.decode, filesData)
                if success then
                    result.files = files
                end
            end

            local pathWithSlash = Y().path .. "/"
            local pathLen = #pathWithSlash

            for hddPath in pairs(HDD.storage) do
                if hddPath:sub(1, pathLen) == pathWithSlash then
                    local remainingPath = hddPath:sub(pathLen + 1)
                    local nextSegment = split(remainingPath, "/")[1]

                    if nextSegment and not remainingPath:sub(#nextSegment + 1):find("/") then
                        local dirData = HDD.storage[hddPath]
                        local success, decoded = pcall(json.decode, dirData)
                        if success and type(decoded) == "table" then
                            result.directories[nextSegment] = true
                        end
                    end
                end
            end

            local dirList = {}
            for dir in pairs(result.directories) do
                table.insert(dirList, dir)
            end
            result.directories = dirList
            Y().callback(result.files, result.directories)
        end)
    end)
end

function fileSystem:mkDir(path, callback, absolute)
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback, absolute = absolute}
        if not Y().absolute then
            Y().path = "files/" .. Y().path
        end
        HDD:write(path, "{}", function(success)
            LDX(success)
            Y().callback(X(), X() and NIL or "Failed to create directory")
        end)
    end)
end

function fileSystem:rmDir(path, callback, absolute)
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback, absolute = absolute}
        if not Y().absolute then
            Y().path = "files/" .. Y().path
        end
        HDD:read(Y().path, function(data)
            if data == "" then
                Y().callback(FALSE, "Directory not found")
                return
            end
            HDD.usedSpace = (HDD.usedSpace or 0) - #data
            HDD.storage[Y().path] = NIL
            Y().callback(TRUE)
        end)
    end)
end

function fileSystem:isDirectory(path, callback, absolute)
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback, absolute = absolute, self = self}
        if not Y().absolute then
            Y().path = "files/" .. Y().path
        end
        Y().self:getTemp(function (temp)
            LDX(temp)
            local parts = split(Y().path, "/")
            local lastPart = parts[#parts]

            local hasExtension = #split(lastPart, ".") > 1

            if hasExtension then
                Y().callback(FALSE)
                return
            end

            if X()[Y().path] then
                Y().callback(type(X()[Y().path]) == "table")
                return
            end

            HDD:read(Y().path, function(data)
                if data == "" then
                    Y().callback(FALSE)
                    return
                end

                local success, decoded = pcall(json.decode, data)
                if success and type(decoded) == "table" then
                    Y().callback(TRUE)
                else
                    Y().callback(FALSE)
                end
            end)  
        end)
    end)
end

return fileSystem
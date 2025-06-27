-- fileSystem.lua
local json = require("json")
local HDD

local temp = {}
local fileSystem
fileSystem = {
    version = "1.0",
}

local function split(str, delimiter)
    local result = {}
    if not str then return result end
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
        temp = {}

        HDD:read("/", function(files)
            LDX(files)
            if X() == "" or X() == nil then
                print("[fileSystem] root '/' is missing. Creating...")
                fileSystem:mkDir("/", function(success, err)
                    if not success then
                        Y().callback(false, "Failed to create root directory: " .. (err or ""))
                        return
                    end
                    print("[fileSystem] root '/' created.")
                    Y().callback(TRUE)
                end, true) -- absolute path
            else
                Y().callback(TRUE)
            end
        end)
    end)
end

function fileSystem:open(path, mode, absolute)
    if not absolute then
        path = (path == "/" and "/" or ("/" .. path))
    end
    mode = mode or "r"
    local parts = split(path, "/")
    local fileName = parts[#parts] or ""
    if #parts > 0 then
        table.remove(parts, #parts)
    end
    local folderPath = "/" .. table.concat(parts, "/")
    local fileExt = split(fileName, ".")[2] or ""

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
                if Y().self.closed then Y().callback(NIL, "File is closed"); return end
                if Y().self.mode ~= "r" and Y().self.mode ~= "r+" then Y().callback(NIL, "Permission denied for read"); return end

                if temp[Y().self.path] then
                    Y().callback(temp[Y().self.path])
                    return
                end
                
                HDD:read(Y().self.folderPath, function(data)
                    if data == "" or data == nil then Y().callback(NIL, "Folder not found: " .. Y().self.folderPath); return end
                    local success, files = pcall(json.decode, data)
                    if not success then Y().callback(NIL, "Failed to parse folder data"); return end
                    
                    if not files[Y().self.fileName] then Y().callback(NIL, "File not found: " .. Y().self.fileName); return end

                    temp[Y().self.path] = files[Y().self.fileName]
                    
                    Y().callback(files[Y().self.fileName])
                end)
            end)
        end,
        write = function(self, data, callback)
            fileSystem.__addThread(function ()
                LDY{self = self, callback = callback, data = data}
                if Y().self.closed then Y().callback(FALSE, "File is closed"); return end
                if Y().self.mode ~= "w" and Y().self.mode ~= "w+" then Y().callback(FALSE, "Permission denied for write"); return end

                HDD:read(Y().self.folderPath, function(hddData)
                    local files = {}
                    if hddData == "" or hddData == nil then Y().callback(false, "Directory does not exist: " .. Y().self.folderPath); return end
                    
                    local success, decoded = pcall(json.decode, hddData)
                    if success then files = decoded else Y().callback(false, "Could not parse directory data"); return end
                    
                    files[Y().self.fileName] = Y().data
                    
                    HDD:write(Y().self.folderPath, json.encode(files), function(writeSuccess)
                        if writeSuccess then
                            temp[Y().self.path] = Y().data
                            temp[Y().self.folderPath] = files
                        end
                        Y().callback(writeSuccess, writeSuccess and NIL or "Failed to write to HDD")
                    end)
                end)
            end)
        end,
        remove = function(self, callback)
            fileSystem.__addThread(function ()
                LDY{self = self, callback = callback}
                if Y().self.closed then Y().callback(false, "File is closed"); return end

                HDD:read(Y().self.folderPath, function(data)
                    if data == "" or data == nil then Y().callback(FALSE, "Folder not found"); return end
                    local success, files = pcall(json.decode, data)
                    if not success then Y().callback(FALSE, "Failed to parse folder data"); return end
                    if not files[Y().self.fileName] then Y().callback(FALSE, "File not found"); return end
                    
                    files[Y().self.fileName] = NIL
                    
                    HDD:write(Y().self.folderPath, json.encode(files), function(writeSuccess)
                        if writeSuccess then
                            temp[Y().self.path] = nil
                            temp[Y().self.folderPath] = files
                        end
                        Y().callback(writeSuccess, writeSuccess and NIL or "Failed to remove file")
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
    if not absolute then path = "/" .. path end

    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback}

        HDD:read(Y().path, function(filesData)
            local result = { files = {}, directories = {} }
            if filesData and filesData ~= "" then
                local success, files = pcall(json.decode, filesData)
                if success and type(files) == 'table' then result.files = files else Y().callback(nil, nil); return end
            end

            local pathWithSlash = (Y().path == "/" and "/" or (Y().path .. "/"))
            for hddPath, content in pairs(HDD.storage) do
                if string.sub(hddPath, 1, #pathWithSlash) == pathWithSlash and hddPath ~= Y().path then
                    local remainingPath = string.sub(hddPath, #pathWithSlash + 1)
                    local nextSegment = split(remainingPath, "/")[1]
                    if nextSegment and nextSegment ~= "" then
                        local success, decoded = pcall(json.decode, content)
                        if success and type(decoded) == 'table' then
                            result.directories[nextSegment] = true
                        end
                    end
                end
            end

            local dirList = {}
            for dir in pairs(result.directories) do table.insert(dirList, dir) end
            result.directories = dirList
            Y().callback(result.files, result.directories)
        end)
    end)
end

function fileSystem:mkDir(path, callback, absolute)
    if not absolute then path = "/" .. path end
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback}
        HDD:read(Y().path, function(data)
            if data ~= "" and data ~= nil then Y().callback(false, "File or directory already exists"); return end
            HDD:write(Y().path, "{}", function(success)
                if success then
                    local parts = split(Y().path, "/")
                    table.remove(parts, #parts)
                    local parentPath = "/" .. table.concat(parts, "/")
                    temp[parentPath] = nil
                end
                Y().callback(success, success and NIL or "Failed to create directory")
            end)
        end)
    end)
end

function fileSystem:rmDir(path, callback, absolute)
    if not absolute then path = "/" .. path end
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback}
        HDD:read(Y().path, function(data)
            if data == "" or data == nil then Y().callback(FALSE, "Directory not found"); return end

            HDD:write(Y().path, NIL, function ()
                temp[Y().path] = nil
                local parts = split(Y().path, "/")
                table.remove(parts, #parts)
                local parentPath = "/" .. table.concat(parts, "/")
                temp[parentPath] = nil
                
                Y().callback(TRUE)
            end)
        end)
    end)
end

function fileSystem:isDirectory(path, callback, absolute)
    if not absolute then path = "/" .. path end
    fileSystem.__addThread(function ()
        LDY{path = path, callback = callback}

        if temp[Y().path] then
            Y().callback(type(temp[Y().path]) == "table")
            return
        end

        HDD:read(Y().path, function(data)
            if data == "" or data == nil then Y().callback(FALSE); return end
            local success, decoded = pcall(json.decode, data)
            local isDir = success and type(decoded) == "table"
            
            if isDir then temp[Y().path] = decoded end

            Y().callback(isDir)
        end)
    end)
end

return fileSystem

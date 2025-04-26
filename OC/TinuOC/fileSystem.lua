local json = require("json")
local HDD = HDD

local temp = {}
local fileSystem = {
    version = "1.0",
    getTemp = function(self)
        temp = RAM and RAM:read(0) or {}
        return temp
    end,
    saveTemp = function(self)
        if RAM then
            return RAM:write(0, temp)
        end
        return false
    end,
}

local function split(str, delimiter)
    local result = {}
    for part in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

function fileSystem:init(callback)
    self:saveTemp()
    HDD:read("trash", function(backet)
        if backet == "" then
            self:mkDir('trash', function(success)
                if not success then
                    callback(false, "Failed to create backet folder")
                    return
                end
                print("[fileSystem] created backet folder")
                HDD:read("files", function(files)
                    if files == "" then
                        self:mkDir('files', function(success)
                            if not success then
                                callback(false, "Failed to create files folder")
                                return
                            end
                            print("[fileSystem] created files folder")
                            callback(true)
                        end, true)
                    else
                        callback(true)
                    end
                end)
            end, true)
        else
            callback(true)
        end
    end)
end

function fileSystem:open(path, mode)
    path = "files/" .. path
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
            if self.closed then
                callback(nil, "File is closed")
                return
            end
            if self.mode ~= "r" then
                callback(nil, "Permission denied for read: " .. self.path)
                return
            end

            local temp = fileSystem:getTemp()
            if temp[self.path] then
                callback(temp[self.path])
                return
            end

            local function findFile(files)
                if files[self.fileName] then
                    temp[self.path] = files[self.fileName]
                    fileSystem:saveTemp()
                    callback(files[self.fileName])
                    return true
                end
                return false
            end

            if temp[self.folderPath] then
                if findFile(temp[self.folderPath]) then
                    return
                end
            end

            HDD:read(self.folderPath, function(data)
                if data == "" then
                    callback(nil, "Folder not found: " .. self.folderPath)
                    return
                end
                local success, files = pcall(json.decode, data)
                if not success then
                    callback(nil, "Failed to parse folder data: " .. self.folderPath)
                    return
                end
                temp[self.folderPath] = files
                if not findFile(files) then
                    callback(nil, "File not found: " .. self.fileName)
                end
                fileSystem:saveTemp()
            end)
        end,
        write = function(self, data, callback)
            if self.closed then
                callback(false, "File is closed")
                return
            end
            if self.mode ~= "w" then
                callback(false, "Permission denied for write: " .. self.path)
                return
            end

            local temp = fileSystem:getTemp()
            temp[self.path] = data

            local function updateFiles(files)
                files = files or {}
                files[self.fileName] = data
                temp[self.folderPath] = files
                fileSystem:saveTemp()
                HDD:write(self.folderPath, json.encode(files), function(success)
                    callback(success, success and nil or "Failed to write to HDD")
                end)
            end

            if temp[self.folderPath] then
                updateFiles(temp[self.folderPath])
                return
            end

            HDD:read(self.folderPath, function(hddData)
                local files = {}
                if hddData ~= "" then
                    local success, decoded = pcall(json.decode, hddData)
                    if success then
                        files = decoded
                    end
                end
                updateFiles(files)
            end)
        end,
        remove = function(self, callback, isTrash)
            if self.closed then
                callback(false, "File is closed")
                return
            end
            
            HDD:read(self.folderPath, function(data)
                if data == "" then
                    callback(false, "Folder not found: " .. self.folderPath)
                    return
                end
                
                local success, files = pcall(json.decode, data)
                if not success then
                    callback(false, "Failed to parse folder data")
                    return
                end
                
                if not files[self.fileName] then
                    callback(false, "File not found: " .. self.fileName)
                    return
                end
                local oldValue = files[self.fileName]
                files[self.fileName] = nil
                HDD:write(self.folderPath, json.encode(files), function(success)
                        if success then
                            local temp = fileSystem:getTemp()
                            temp[self.path] = nil
                            if temp[self.folderPath] then
                                temp[self.folderPath][self.fileName] = nil
                            end
                            fileSystem:saveTemp()
                            HDD.usedSpace = (HDD.usedSpace or 0) - #data * 8
                            if not isTrash then
                                HDD:read("trash", function (Trashfiles)
                                    Trashfiles = json.decode(Trashfiles)
                                    Trashfiles[self.fileName] = oldValue
                                    HDD:write("trash", json.encode(Trashfiles), function (success)
                                        if not success then
                                            print("[fileSystem] Failed move file in trush")
                                        end
                                    end)
                                end)
                            end
                        end
                        callback(success, success and nil or "Failed to remove file")
                    end)
                end)
        end,
        close = function()
            file.closed = true
        end
    }
    return file
end

function fileSystem:getDirFiles(path, callback)
    path = "files/" .. path
    local temp = self:getTemp()
    if temp[path] then
        callback(temp[path])
        return nil
    end
    HDD:read(path, function (files)
        files = json.decode(files)
        temp[path] = files
        self:saveTemp()
        callback(files)
    end)
end

function fileSystem:mkDir(path, callback, absolute)
    if not absolute then
        path = "files/" .. path
    end
    HDD:write(path, "{}", function(success)
        callback(success, success and nil or "Failed to create directory")
    end)
end

function fileSystem:rmDir(path, callback, absolute)
    if not absolute then
        path = "files/" .. path
    end
    HDD:read(path, function(data)
        if data == "" then
            callback(false, "Directory not found")
            return
        end
        HDD.usedSpace = (HDD.usedSpace or 0) - #data * 8
        HDD.storage[path] = nil
        callback(true)
    end)
end

return fileSystem
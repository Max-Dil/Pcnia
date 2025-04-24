-- GPU/Avrora.lua
local bit = require("bit")
local ffi = require("ffi")

local Avrora = {
    model = "Avrora GTX",
    version = "1.0",
    manufacturer = "StimorGPU",
    architecture = "STNA",

    -- Память
    MEMORY = {},
    memory_size = 500,        -- MB
    memory_type = "GDDR1X",
    memory_bus_width = 8,
    memory_bandwidth = 0.05, -- GB/s
    memory_usage = 0,       -- MB used

    baseClockSpeed = 500,
    boostClockSpeed = 700,
    currentClockSpeed = 200,
    memoryClockSpeed = 100,

    TDP = 25,
    max_temperature = 95,
    current_temperature = 40,
    power_usage = 0,
    coolingRate = 0.5,
    heatingRate = 0.5,
    fan_speed = 30,
    max_fan_speed = 100,

    autoBoost = true,
    power_limit = 100,
    voltage = 1.1,

    maxClockSpeed = 700,
    minClockSpeed = 10,
    boostThreshold = 0.5,
    throttleThreshold = 0.9,

    CUDA_cores = 46,
    RT_cores = 18,
    TMUs = 16,
    ROPs = 16,

    utilization = {
        core = 1,
        memory = 0,
        power = 0,
    },

    resolution = {width = 640, height = 480},
    color_depth = 32,
    fps = 0,
    frame_buffer = {},
    frame_time = 0,

    connected_cpu = nil,

    pixel_draw_count = 0,
}

function Avrora:init(cpu)
    local memory_bytes = self.memory_size * 1024
    for i = 0, memory_bytes - 1 do
        self.MEMORY[i] = 0
    end

    self:initFrameBuffer()

    self.connected_cpu = cpu
    return self
end

function Avrora:initFrameBuffer()
    self.frame_buffer = {}
    for y = 1, self.resolution.height do
        self.frame_buffer[y] = {}
        for x = 1, self.resolution.width do
            self.frame_buffer[y][x] = {0, 0, 0} -- RGB
        end
    end
end

function Avrora:setResolution(width, height)
    if width * height * (self.color_depth/8) > self.memory_size * 1024 then
        print("Error: Not enough video memory for this resolution")
        return false
    end
    
    self.resolution.width = width
    self.resolution.height = height
    self:initFrameBuffer()
    return true
end

function Avrora:update(dt)

    self:updateTemperature(dt)

    self:autoBoostClock()

    self:updatePowerUsage()

    self:updateFanSpeed(dt)

        local speed_factor = self.currentClockSpeed / self.baseClockSpeed
    if self.utilization.core > 0 then
        self.frame_time = self.frame_time + dt * (1 / speed_factor)
        local target_frame_time = 1 / (self.fps > 0 and self.fps or 60)
        
        if self.frame_time >= target_frame_time then
            self:renderFrame()
            self.frame_time = self.frame_time - target_frame_time
        end
    end
end

function Avrora:updateTemperature(dt)

    local heat_factor = (self.utilization.core/100) * (self.currentClockSpeed/self.baseClockSpeed)
    self.current_temperature = self.current_temperature + heat_factor * self.heatingRate * dt

    local cooling_factor = (self.fan_speed/100) * self.coolingRate * dt
    self.current_temperature = math.max(25, self.current_temperature - cooling_factor)

    if self.current_temperature > self.max_temperature * 0.9 then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed * 0.99
        )
    end
end

function Avrora:autoBoostClock()
    if not self.autoBoost then return end

    if self.current_temperature > self.max_temperature * self.throttleThreshold then
        self.currentClockSpeed = math.max(
            self.minClockSpeed,
            self.currentClockSpeed * 0.95
        )
        return
    end

    local targetBoost = self.baseClockSpeed
    
    if self.utilization.core > self.boostThreshold * 100 then
        targetBoost = self.boostClockSpeed
    elseif self.utilization.core > self.boostThreshold * 50 then
        targetBoost = (self.baseClockSpeed + self.boostClockSpeed) / 2
    end

    if self.currentClockSpeed < targetBoost then
        self.currentClockSpeed = math.min(
            targetBoost,
            self.currentClockSpeed + 25
        )
    elseif self.currentClockSpeed > targetBoost then
        self.currentClockSpeed = math.max(
            targetBoost,
            self.currentClockSpeed - 15
        )
    end
end

function Avrora:updatePowerUsage()
    local power_factor = (self.utilization.core/100) * (self.currentClockSpeed/self.maxClockSpeed)
    self.power_usage = self.TDP * power_factor * (self.power_limit/100)
    self.utilization.power = (self.power_usage / self.TDP) * 100
end

function Avrora:updateFanSpeed(dt)
    local target_speed = 30 + (self.current_temperature - 40) * 2
    target_speed = math.min(self.max_fan_speed, math.max(30, target_speed))
    
    if target_speed > self.fan_speed then
        self.fan_speed = math.min(target_speed, self.fan_speed + 100 * dt)
    else
        self.fan_speed = math.max(target_speed, self.fan_speed - 50 * dt)
    end
end

function Avrora:clear()
    local changed_pixels = 0
    for y = 1, self.resolution.height do
        for x = 1, self.resolution.width do
            if self.frame_buffer[y][x][1] ~= 0 or self.frame_buffer[y][x][2] ~= 0 or self.frame_buffer[y][x][3] ~= 0 then
                changed_pixels = changed_pixels + 1
                self.frame_buffer[y][x] = {0, 0, 0}
            end
        end
    end
    self.pixel_draw_count = changed_pixels
end

-- for y = 1, self.resolution.height do
--     for x = 1, self.resolution.width do
--         if math.random() < 0.5 then
--             self.frame_buffer[y][x] = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}
--             self.pixel_draw_count = self.pixel_draw_count + 1
--         end
--     end
-- end

function Avrora:getCore()
    return Avrora.CUDA_cores + (Avrora.RT_cores * 0.8) + (Avrora.TMUs * 0.6) + (Avrora.ROPs * 0.4)
end

local cores = Avrora:getCore()
function Avrora:renderFrame()
    local changed_pixels = 0
    local memory = 0
    for y = 1, self.resolution.height do
        for x = 1, self.resolution.width do
            if self.frame_buffer[y][x][1] ~= 0 or self.frame_buffer[y][x][2] ~= 0 or self.frame_buffer[y][x][3] ~= 0 then
                changed_pixels = changed_pixels + 1
                memory = memory + (#tostring(self.frame_buffer[y][x][1]) + #tostring(self.frame_buffer[y][x][2]) + #tostring(self.frame_buffer[y][x][3]))/64
                if memory / self.memory_size > 100 then
                    memory = 0
                    Avrora:clear()
                    changed_pixels = 0
                    self.utilization.core = 1
                end
            end
        end
    end
    self.pixel_draw_count = changed_pixels

    self.utilization.core = math.max(1,math.min(100, changed_pixels/cores))
    self.utilization.memory = memory / self.memory_size
    self.memory_usage = memory
    self.fps = (60 * (self.currentClockSpeed/self.baseClockSpeed)) / (1 + self.utilization.core/100)
    self.pixel_draw_count = 0
end

function Avrora:getPowerConsumption()
    return self.power_usage
end

function Avrora:drawPixel(x, y, color)
    if x >= 1 and x <= self.resolution.width and
       y >= 1 and y <= self.resolution.height then
        self.frame_buffer[y][x] = color
    else
        print(string.format("Invalid pixel coordinates (%d, %d)", x, y))
    end
end

function Avrora:drawText(x, y, text, color, scale)
    color = color or {255, 255, 255}
    scale = scale or 1

    local font = {
        -- Цифры
        ['0'] = {0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E},
        ['1'] = {0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E},
        ['2'] = {0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F},
        ['3'] = {0x0E, 0x11, 0x01, 0x06, 0x01, 0x11, 0x0E},
        ['4'] = {0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02},
        ['5'] = {0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E},
        ['6'] = {0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E},
        ['7'] = {0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08},
        ['8'] = {0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E},
        ['9'] = {0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C},
        
        -- Заглавные буквы
        ['A'] = {0x04, 0x0A, 0x11, 0x11, 0x1F, 0x11, 0x11},
        ['B'] = {0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E},
        ['C'] = {0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E},
        ['D'] = {0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E},
        ['E'] = {0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F},
        ['F'] = {0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10},
        ['G'] = {0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F},
        ['H'] = {0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11},
        ['I'] = {0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E},
        ['J'] = {0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C},
        ['K'] = {0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11},
        ['L'] = {0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F},
        ['M'] = {0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11},
        ['N'] = {0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11},
        ['O'] = {0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E},
        ['P'] = {0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10},
        ['Q'] = {0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D},
        ['R'] = {0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11},
        ['S'] = {0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E},
        ['T'] = {0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04},
        ['U'] = {0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E},
        ['V'] = {0x11, 0x11, 0x11, 0x11, 0x0A, 0x0A, 0x04},
        ['W'] = {0x11, 0x11, 0x11, 0x15, 0x15, 0x1B, 0x11},
        ['X'] = {0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11},
        ['Y'] = {0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04},
        ['Z'] = {0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F},
        
        -- Строчные буквы (немного уменьшенные)
        ['a'] = {0x00, 0x00, 0x0E, 0x01, 0x0F, 0x11, 0x0F},
        ['b'] = {0x10, 0x10, 0x16, 0x19, 0x11, 0x11, 0x1E},
        ['c'] = {0x00, 0x00, 0x0E, 0x11, 0x10, 0x11, 0x0E},
        ['d'] = {0x01, 0x01, 0x0D, 0x13, 0x11, 0x11, 0x0F},
        ['e'] = {0x00, 0x00, 0x0E, 0x11, 0x1F, 0x10, 0x0E},
        ['f'] = {0x06, 0x09, 0x08, 0x1C, 0x08, 0x08, 0x08},
        ['g'] = {0x00, 0x0F, 0x11, 0x11, 0x0F, 0x01, 0x0E},
        ['h'] = {0x10, 0x10, 0x16, 0x19, 0x11, 0x11, 0x11},
        ['i'] = {0x04, 0x00, 0x0C, 0x04, 0x04, 0x04, 0x0E},
        ['j'] = {0x02, 0x00, 0x06, 0x02, 0x02, 0x12, 0x0C},
        ['k'] = {0x10, 0x10, 0x12, 0x14, 0x18, 0x14, 0x12},
        ['l'] = {0x0C, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E},
        ['m'] = {0x00, 0x00, 0x1A, 0x15, 0x15, 0x11, 0x11},
        ['n'] = {0x00, 0x00, 0x16, 0x19, 0x11, 0x11, 0x11},
        ['o'] = {0x00, 0x00, 0x0E, 0x11, 0x11, 0x11, 0x0E},
        ['p'] = {0x00, 0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10},
        ['q'] = {0x00, 0x0D, 0x13, 0x11, 0x0F, 0x01, 0x01},
        ['r'] = {0x00, 0x00, 0x16, 0x19, 0x10, 0x10, 0x10},
        ['s'] = {0x00, 0x00, 0x0F, 0x10, 0x0E, 0x01, 0x1E},
        ['t'] = {0x08, 0x08, 0x1C, 0x08, 0x08, 0x09, 0x06},
        ['u'] = {0x00, 0x00, 0x11, 0x11, 0x11, 0x13, 0x0D},
        ['v'] = {0x00, 0x00, 0x11, 0x11, 0x11, 0x0A, 0x04},
        ['w'] = {0x00, 0x00, 0x11, 0x11, 0x15, 0x15, 0x0A},
        ['x'] = {0x00, 0x00, 0x11, 0x0A, 0x04, 0x0A, 0x11},
        ['y'] = {0x00, 0x11, 0x11, 0x0F, 0x01, 0x11, 0x0E},
        ['z'] = {0x00, 0x00, 0x1F, 0x02, 0x04, 0x08, 0x1F},
        
        -- Символы
        [' '] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
        ['.'] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04},
        [','] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x04},
        [':'] = {0x00, 0x00, 0x04, 0x00, 0x04, 0x00, 0x00},
        ['!'] = {0x04, 0x04, 0x04, 0x04, 0x04, 0x00, 0x04},
        ['?'] = {0x0E, 0x11, 0x01, 0x02, 0x04, 0x00, 0x04},
        ['-'] = {0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00},
        ['_'] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F},
        ['+'] = {0x00, 0x04, 0x04, 0x1F, 0x04, 0x04, 0x00},
        ['/'] = {0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x00},
        ['\\']= {0x00, 0x10, 0x08, 0x04, 0x02, 0x01, 0x00},
        ['('] = {0x02, 0x04, 0x08, 0x08, 0x08, 0x04, 0x02},
        [')'] = {0x08, 0x04, 0x02, 0x02, 0x02, 0x04, 0x08},
        ['['] = {0x0E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0E},
        [']'] = {0x0E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0E},
        ['{'] = {0x06, 0x08, 0x08, 0x10, 0x08, 0x08, 0x06},
        ['}'] = {0x0C, 0x02, 0x02, 0x01, 0x02, 0x02, 0x0C},
        ['<'] = {0x02, 0x04, 0x08, 0x10, 0x08, 0x04, 0x02},
        ['>'] = {0x08, 0x04, 0x02, 0x01, 0x02, 0x04, 0x08},
        ['='] = {0x00, 0x00, 0x1F, 0x00, 0x1F, 0x00, 0x00},
        ['@'] = {0x0E, 0x11, 0x17, 0x15, 0x17, 0x10, 0x0E},
        ['#'] = {0x0A, 0x0A, 0x1F, 0x0A, 0x1F, 0x0A, 0x0A},
        ['$'] = {0x04, 0x0F, 0x14, 0x0E, 0x05, 0x1E, 0x04},
        ['%'] = {0x18, 0x19, 0x02, 0x04, 0x08, 0x13, 0x03},
        ['^'] = {0x04, 0x0A, 0x11, 0x00, 0x00, 0x00, 0x00},
        ['&'] = {0x0C, 0x12, 0x14, 0x08, 0x15, 0x12, 0x0D},
        ['*'] = {0x00, 0x04, 0x15, 0x0E, 0x15, 0x04, 0x00},
        ['"'] = {0x0A, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00},
        ['\'']= {0x04, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00},
        ['~'] = {0x00, 0x00, 0x0A, 0x15, 0x00, 0x00, 0x00},
        ['`'] = {0x08, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00},
        ['|'] = {0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04},
        ['°'] = {0x0E, 0x0A, 0x0E, 0x00, 0x00, 0x00, 0x00},
    }

    local char_width = 5 * scale
    local char_spacing = 1 * scale
    local line_height = 8 * scale

    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    for line_num, line in ipairs(lines) do
        local current_y = y + (line_num - 1) * line_height

        if current_y + 7*scale <= self.resolution.height then
            for i = 1, #line do
                local char = line:sub(i, i)
                local glyph = font[char] or font['?']
                local current_x = x + (i - 1) * (char_width + char_spacing)

                if current_x + char_width > 0 then
                    if current_x <= self.resolution.width then
                        for row = 1, 7 do
                            local row_data = glyph[row] or 0

                            for col = 0, 4 do
                                if bit.band(row_data, bit.lshift(1, 4 - col)) ~= 0 then
                                    for sy = 0, scale - 1 do
                                        for sx = 0, scale - 1 do
                                            local px = current_x + col * scale + sx
                                            local py = current_y + (row - 1) * scale + sy

                                            if px >= 1 and px <= self.resolution.width and
                                               py >= 1 and py <= self.resolution.height then
                                                self:drawPixel(px, py, color)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                end

                if current_x + char_width > self.resolution.width then
                    break
                end
            end
        end
    end

    self.pixel_draw_count = self.pixel_draw_count + #text * 35 * scale * scale
end

function Avrora:getFrameBuffer()
    return self.frame_buffer
end

function Avrora:getInfo()
    return {
        model = self.model,
        memory = string.format("%dMB %s (%d-bit)", 
                  self.memory_size * 1024, 
                  self.memory_type, 
                  self.memory_bus_width),
        clock = string.format("%d/%d MHz (Memory: %d MHz)", 
                 self.currentClockSpeed, 
                 self.boostClockSpeed, 
                 self.memoryClockSpeed),
        temperature = string.format("%.1f°C (Fan: %d%%)", 
                       self.current_temperature, 
                       self.fan_speed),
        power = string.format("%.1f/%dW (%.1f%%)", 
                self.power_usage, 
                self.TDP, 
                self.utilization.power),
        utilization = string.format("Core: %.1f%%, Memory: %.1f%%", 
                       self.utilization.core, 
                       self.utilization.memory),
        fps = string.format("%.1f FPS", self.fps),
        resolution = string.format("%dx%d (%d-bit)", 
                      self.resolution.width, 
                      self.resolution.height, 
                      self.color_depth),
        memory_usage = string.format("%.1f/%d MB", 
                        self.memory_usage, 
                        self.memory_size * 1024),
        architecture = self.architecture,
        cores = string.format("CUDA: %d, RT: %d, TMUs: %d, ROPs: %d", 
                 self.CUDA_cores, 
                 self.RT_cores, 
                 self.TMUs, 
                 self.ROPs)
    }
end

return Avrora
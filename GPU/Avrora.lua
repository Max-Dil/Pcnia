-- GPU/Avrora.lua

--[[
Самая первая и днишенская видео карта, ужасно оптимизирована и слабая
]]
local Avrora = {
    model = "Avrora GTX",
    version = "1.0",
    manufacturer = "StimorGPU",
    architecture = "STNA",

    -- Память
    MEMORY = {},
    memory_size = 100,        -- MB
    memory_type = "GDDR1X",
    memory_bus_width = 8,
    memory_bandwidth = 0.05, -- GB/s
    memory_usage = 0,       -- MB used

    baseClockSpeed = 500,
    boostClockSpeed = 700,
    currentClockSpeed = 200,
    memoryClockSpeed = 100,

    TDP = 50,
    max_temperature = 95,
    current_temperature = 40,
    power_usage = 0,
    coolingRate = 0.5,
    heatingRate = 0.5,
    fan_speed = 30,
    max_fan_speed = 100,

    autoBoost = true,
    power_limit = 60,
    voltage = 1.1,

    maxClockSpeed = 700,
    minClockSpeed = 10,
    boostThreshold = 0.5,
    throttleThreshold = 0.9,

    CUDA_cores = 406,
    RT_cores = 108,
    TMUs = 106,
    ROPs = 106,

    utilization = {
        core = 1,
        memory = 0,
        power = 0,
    },

    resolution = {width = 400, height = 300},
    color_depth = 32,
    fps = 0,
    frame_buffer = {},
    frame_time = 0,
    render_buffer = {},

    connected_cpu = nil,

    pixel_draw_count = 0,

    driver = "Unakoda",

    input_current = 100,
    current_fps = 30
}

local function copyBuffer()
    Avrora.render_buffer = {}
    for y = 1, #Avrora.frame_buffer do
        local new_row = {}
        local src_row = Avrora.frame_buffer[y]
        for x = 1, #src_row do
            new_row[x] = {src_row[x][1], src_row[x][2], src_row[x][3]}
        end
        Avrora.render_buffer[y] = new_row
    end
end

function Avrora:init(cpu)
    local driver = require("GPU.DRIVERS."..self.driver)
    local memory_bytes = self.memory_size * 1024
    for i = 0, memory_bytes - 1 do
        self.MEMORY[i] = 0
    end

    self:initFrameBuffer()

    self.connected_cpu = cpu
    driver:init(self)
    return self
end

function Avrora:initFrameBuffer()
    for y = 1, #(self.frame_buffer or {}) do
        for x = 1, self.frame_buffer[y], 1 do
            self.frame_buffer[y][x] = nil
            self.frame_buffer[y] = nil
        end
    end

    self.frame_buffer = {}
    for y = 1, self.resolution.height do
        self.frame_buffer[y] = {}
        for x = 1, self.resolution.width do
            self.frame_buffer[y][x] = {0, 0, 0} -- RGB
        end
    end
    copyBuffer()
end

function Avrora:setResolution(width, height)
    if width * height * (self.color_depth/8) > self.memory_size * 1024 then
        print("Error: Not enough video memory for this resolution")
        return false
    end
    
    self.resolution.width = width
    self.resolution.height = height
    self:initFrameBuffer()

    collectgarbage("collect")
    return true
end

function Avrora:update(dt)
    if self.input_current < self.power_usage then self.input_current = 0 return end

    self:updateTemperature(dt)

    self:autoBoostClock()

    self:updatePowerUsage()

    self:updateFanSpeed(dt)

        local speed_factor = self.currentClockSpeed / self.baseClockSpeed
    if self.utilization.core > 0 then
        self.frame_time = self.frame_time + dt * (1 / speed_factor)
        local target_frame_time = 1 / (self.fps > 0 and self.fps or 1)
        
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
    local power_factor = (self.utilization.core/50) * (self.currentClockSpeed/self.maxClockSpeed) * (self.fan_speed/self.max_fan_speed)
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

    collectgarbage("collect")
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
    local changed_pixels = self.pixel_draw_count
    local memory = 0
    local is_remove = false
    for y = 1, self.resolution.height do
        for x = 1, self.resolution.width do
            if self.frame_buffer[y][x][1] ~= 0 or self.frame_buffer[y][x][2] ~= 0 or self.frame_buffer[y][x][3] ~= 0 then
                changed_pixels = changed_pixels + 1
                memory = memory + 85
                if is_remove then
                    changed_pixels = changed_pixels - 1
                    memory = memory - 85
                    self.frame_buffer[y][x] = {0,0,0}
                end
                if memory / 1024 / self.memory_size > 100 then
                    is_remove = true
                end
            end
        end
    end
    self.pixel_draw_count = changed_pixels

    copyBuffer()

    self.utilization.core = math.max(1,math.min(100, changed_pixels/cores))
    self.utilization.memory = memory / 1024 / self.memory_size
    self.memory_usage = memory / 1024
    self.fps = (self.current_fps * (self.currentClockSpeed/self.baseClockSpeed)) * (1 - self.utilization.core/100)
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

function Avrora:getFrameBuffer()
    return self.render_buffer
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
                        self.memory_size),
        architecture = self.architecture,
        cores = string.format("CUDA: %d, RT: %d, TMUs: %d, ROPs: %d", 
                 self.CUDA_cores, 
                 self.RT_cores, 
                 self.TMUs, 
                 self.ROPs)
    }
end

return Avrora
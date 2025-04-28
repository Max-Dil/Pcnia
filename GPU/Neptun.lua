-- GPU/Neptun.lua

--[[
Видео крата на новой аритектуре, оптимизирована за счет использования быстрого буфера и мощнее своих предсшественников
однако и энергии требует больше
]]
local Neptun = {
    model = "Neptun GTX",
    version = "1.0",
    manufacturer = "StimorGPU",
    architecture = "NATS",

    -- Память
    MEMORY = {},
    memory_size = 500,        -- MB
    memory_type = "GDDR2",
    memory_bus_width = 16,
    memory_bandwidth = 0.2, -- GB/s
    memory_usage = 0,       -- MB used

    baseClockSpeed = 700,
    boostClockSpeed = 900,
    currentClockSpeed = 500,
    memoryClockSpeed = 400,

    TDP = 100,
    max_temperature = 95,
    current_temperature = 50,
    power_usage = 0,
    coolingRate = 0.6,
    heatingRate = 0.5,
    fan_speed = 30,
    max_fan_speed = 100,

    autoBoost = true,
    power_limit = 120,
    voltage = 1.5,

    maxClockSpeed = 900,
    minClockSpeed = 100,
    boostThreshold = 0.5,
    throttleThreshold = 0.9,

    CUDA_cores = 806,
    RT_cores = 208,
    TMUs = 206,
    ROPs = 206,

    utilization = {
        core = 1,
        memory = 0,
        power = 0,
    },

    resolution = {width = 1960, height = 1280},
    color_depth = 32,
    fps = 0,
    frame_buffer = {},
    frame_time = 0,
    render_buffer = {},

    connected_cpu = nil,

    pixel_draw_count = 0,

    driver = "Unakoda",

    input_current = 200,
    current_fps = 30
}

function Neptun:init(cpu)
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

function Neptun:initFrameBuffer()
    self.frame_buffer = {}
    self.back_buffer = {}
    for y = 1, self.resolution.height do
        self.frame_buffer[y] = {}
        for x = 1, self.resolution.width do
            self.frame_buffer[y][x] = {0, 0, 0} -- RGB
        end
    end
end

function Neptun:setResolution(width, height)
    if width * height * (self.color_depth/8) > self.memory_size * 1024 then
        print("Error: Not enough video memory for this resolution")
        return false
    end
    
    self.resolution.width = width
    self.resolution.height = height
    self:initFrameBuffer()
    return true
end

function Neptun:update(dt)
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

function Neptun:updateTemperature(dt)

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

function Neptun:autoBoostClock()
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

function Neptun:updatePowerUsage()
    local power_factor = (self.utilization.core/50) * (self.currentClockSpeed/self.maxClockSpeed) * (self.fan_speed/self.max_fan_speed)
    self.power_usage = self.TDP * power_factor * (self.power_limit/100)
    self.utilization.power = (self.power_usage / self.TDP) * 100
end

function Neptun:updateFanSpeed(dt)
    local target_speed = 30 + (self.current_temperature - 40) * 2
    target_speed = math.min(self.max_fan_speed, math.max(30, target_speed))
    
    if target_speed > self.fan_speed then
        self.fan_speed = math.min(target_speed, self.fan_speed + 100 * dt)
    else
        self.fan_speed = math.max(target_speed, self.fan_speed - 50 * dt)
    end
end

function Neptun:clear()
    self.back_buffer = {}
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
    self.memory_usage = 0
end

-- for y = 1, self.resolution.height do
--     for x = 1, self.resolution.width do
--         if math.random() < 0.5 then
--             self.frame_buffer[y][x] = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}
--             self.pixel_draw_count = self.pixel_draw_count + 1
--         end
--     end
-- end

function Neptun:getCore()
    return Neptun.CUDA_cores + (Neptun.RT_cores * 0.8) + (Neptun.TMUs * 0.6) + (Neptun.ROPs * 0.4)
end

local cores = Neptun:getCore()
function Neptun:renderFrame()
    local changed_pixels = self.pixel_draw_count

    for i =  1, #self.back_buffer do
        self.frame_buffer[self.back_buffer[i][2]][self.back_buffer[i][1]] = self.back_buffer[i][3]
        self.memory_usage = self.memory_usage + 85
        changed_pixels = changed_pixels + 1
        if self.back_buffer[i][3][1] == 0 and self.back_buffer[i][3][2] == 0 and self.back_buffer[i][3][3] == 0 then
            self.memory_usage = self.memory_usage - 85
        end
        self.back_buffer[i] = nil
        if self.memory_usage / 1024 / self.memory_size > 100 then
            break
        end
    end
    self.pixel_draw_count = changed_pixels


    self.utilization.core = math.max(1,math.min(100, changed_pixels/cores))
    self.utilization.memory = self.memory_usage / 1024 / self.memory_size
    self.fps = (self.current_fps * (self.currentClockSpeed/self.baseClockSpeed)) * (1 - self.utilization.core/100)
    self.pixel_draw_count = 0
end

function Neptun:getPowerConsumption()
    return self.power_usage
end

function Neptun:drawPixel(x, y, color)
    if x >= 1 and x <= self.resolution.width and
       y >= 1 and y <= self.resolution.height then
        self.back_buffer[#self.back_buffer+1] = {x, y, color}
    else
        print(string.format("Invalid pixel coordinates (%d, %d)", x, y))
    end
end

function Neptun:getFrameBuffer()
    return self.frame_buffer
end

function Neptun:getInfo()
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

return Neptun
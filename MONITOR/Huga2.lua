-- MONITOR/Huga.lua
local Huga = {
    model = "Huga 800x600 Pro",
    resolution = {width = 800, height = 600},
    pixels = {},
    colorDepth = 16, -- бит на цвет
    powerConsumption = 40, -- Вт
    temperature = 25, -- начальная температура
    maxTemperature = 100,
    isOn = true,
    brightness = 1.0,    -- 0.0 (мин) до 1.0 (макс)
    contrast = 1.0,      -- 0.5 (мин) до 2.0 (макс)
    backlightLevel = 0.8, -- Уровень подсветки (0-1)

    input_current = 30,

    hhz = 30,
    frame_hhz = 0
}

function Huga:setBrightness(level)
    self.brightness = math.max(0.0, math.min(1.0, level))
    self:updatePowerConsumption()
end

function Huga:setContrast(level)
    self.contrast = math.max(0.5, math.min(2.0, level))
end

function Huga:setBacklight(level)
    self.backlightLevel = math.max(0.0, math.min(1.0, level))
    self:updatePowerConsumption()
end

function Huga:updatePowerConsumption()
    self.powerConsumption = 10 + 10 * self.backlightLevel
end

function Huga:applyColorEffects(r, g, b)
    local nr, ng, nb = r/255, g/255, b/255
    
    nr = (nr - 0.5) * self.contrast + 0.5
    ng = (ng - 0.5) * self.contrast + 0.5
    nb = (nb - 0.5) * self.contrast + 0.5

    nr = nr * self.brightness * self.backlightLevel
    ng = ng * self.brightness * self.backlightLevel
    nb = nb * self.brightness * self.backlightLevel

    nr = math.max(0, math.min(1, nr))
    ng = math.max(0, math.min(1, ng))
    nb = math.max(0, math.min(1, nb))

    return nr*255, ng*255, nb*255
end

function Huga:init(gpu)
    self.gpu = gpu
    self:clear()
    self.imageData = love.image.newImageData(self.resolution.width, self.resolution.height)
    return self
end

function Huga:clear()
    self.pixels = {}
    if self.gpu then self.gpu:clear() end
    for y = 1, self.resolution.height do
        self.pixels[y] = {}
        for x = 1, self.resolution.width do
            self.pixels[y][x] = {0, 0, 0} -- R, G, B
        end
    end
end

function Huga:update(dt)
    if self.input_current < self:getPowerConsumption() then self.input_current = 0 return end
    if self.temperature > 25 then
        self.temperature = self.temperature - dt * 0.5
    end
    
    if self.isOn then
        local heatFactor = 0.1 + 0.3 * self.backlightLevel
        self.temperature = math.min(
            self.maxTemperature,
            self.temperature + dt * heatFactor
        )
    end

    self.frame_hhz = self.frame_hhz + dt
    if self.frame_hhz >= 1/self.hhz then
        self.frame_hhz = 0
        if self.isOn and self.gpu and self.gpu.getFrameBuffer then
            local fb = self.gpu:getFrameBuffer()
            if fb then
                for y = 1, math.min(#fb, self.resolution.height) do
                    for x = 1, math.min(#fb[y], self.resolution.width) do
                        if fb[y][x] then
                            self.pixels[y][x] = fb[y][x]
                        end
                    end
                end
            end
        end
    end
end

function Huga:draw()
    if not self.isOn then 
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", 0, 0, 
            self.resolution.width, self.resolution.height)
        return 
    end

    local scaleX = love.graphics.getWidth() / self.resolution.width
    local scaleY = love.graphics.getHeight() / self.resolution.height
    local scale = math.min(scaleX, scaleY)

    for y = 1, self.resolution.height do
        for x = 1, self.resolution.width do
            local color = self.pixels[y][x] or {0, 0, 0}
            if color[1] == nil then
                print(require("json").encode(self.pixels))
                return
            end
            local r, g, b = self:applyColorEffects(color[1], color[2], color[3])
            self.imageData:setPixel(x-1, y-1, r/255, g/255, b/255, 1)
        end
    end

    local image = love.graphics.newImage(self.imageData)
    love.graphics.draw(image, 0, 0, 0, scale, scale)
    image:release()

    if self.brightness < 0.3 or self.backlightLevel < 0.3 then
        love.graphics.setColor(0, 0, 0, 1 - (self.brightness * self.backlightLevel)/0.3)
        love.graphics.rectangle("fill", 0, 0, 
            self.resolution.width * scale, self.resolution.height * scale)
    end
end

function Huga:getInfo()
    return {
        model = self.model,
        resolution = string.format("%dx%d", self.resolution.width, self.resolution.height),
        colorDepth = self.colorDepth,
        powerConsumption = string.format("%.1fW", self.powerConsumption),
        temperature = string.format("%.1f°C", self.temperature),
        status = self.isOn and "ON" or "OFF",
        brightness = string.format("%.0f%%", self.brightness * 100),
        contrast = string.format("%.1f", self.contrast),
        backlight = string.format("%.0f%%", self.backlightLevel * 100)
    }
end

function Huga:getPowerConsumption()
    return self.powerConsumption
end

function Huga:powerOn()
    self.isOn = true
    self:clear()
end

function Huga:powerOff()
    self.isOn = false
end

function Huga:setPowerSaveMode(enabled)
    if enabled then
        self:setBrightness(0.5)
        self:setBacklight(0.5)
        self:setContrast(1.0)
    else
        self:setBrightness(1.0)
        self:setBacklight(0.8)
        self:setContrast(1.2)
    end
end

return Huga
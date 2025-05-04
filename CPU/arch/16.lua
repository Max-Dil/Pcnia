return function (self)
    local regs = {
        AX = 0, BX = 0, CX = 0, DX = 0,
        SI = 0, DI = 0, BP = 0, SP = 0xFFFF,
        IP = 0, FLAGS = 0
    }
    
    local env = {
        MOV = function(dest, src)
            regs[dest] = src and bit.band(src, 0xFFFF) or regs.AX
        end,

        ADD = function(a, b)
            self:applyLoadDelay()
            return self:add16(a or regs.AX, b or 0)
        end,

        SUB = function(a, b)
            self:applyLoadDelay()
            return self:sub16(a or regs.AX, b or 0)
        end,

        AND = function(a, b)
            self:applyLoadDelay()
            regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
            return bit.band(a or regs.AX, b or 0xFFFF)
        end,

        OR = function(a, b)
            self:applyLoadDelay()
            regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
            return bit.bor(a or regs.AX, b or 0xFFFF)
        end,

        XOR = function(a, b)
            self:applyLoadDelay()
            regs.FLAGS = bit.bor(regs.FLAGS, self.FLAGS_MASK.ZERO)
            return bit.bxor(a or regs.AX, b or 0xFFFF)
        end,

        NOT = function(a)
            self:applyLoadDelay()
            return bit.bnot(a or regs.AX) % 0x10000
        end,

        SHL = function(a, b)
            self:applyLoadDelay()
            return bit.lshift(a or regs.AX, b or 1) % 0x10000
        end,

        SHR = function(a, b)
            self:applyLoadDelay()
            return bit.rshift(a or regs.AX, b or 1) % 0x10000
        end,

        LDA = function(v)
            self:applyLoadDelay()
            regs.AX = v
        end,
        STA = function(a)
            self.motherboard:writeMemory(a, regs.AX)
        end,
        LDX = function(v)
            self:applyLoadDelay()
            regs.BX = v
        end,
        LDY = function(v)
            self:applyLoadDelay()
            regs.CX = v
        end,
        STX = function(a)
            self:applyLoadDelay()
            self.motherboard:writeMemory(a, regs.BX)
        end,
        STY = function (a)
            self:applyLoadDelay()
            self.motherboard:writeMemory(a, regs.CX)
        end,

        getReg = function(name)
            self:applyLoadDelay()
            return regs[name] or 0
        end,
        setReg = function(name, value)
            self:applyLoadDelay()
            regs[name] = value
        end,

        DRW = function(x, y, r, g, b)
            self:applyLoadDelay()
            if self.gpu then
                self.gpu:drawPixel(x, y, {r, g, b})
            end
        end,
        DTX = function(x, y, text, color, scale)
            self:applyLoadDelay()
            if self.gpu then
                if self.gpu.driver == "Unakoda" then
                    self.gpu:drawText(x, y, text, color, scale)
                else
                end
            end
        end,
        DRE = function(x, y, width, height, color)
            self:applyLoadDelay()
            if self.gpu then
                if self.gpu then
                    if self.gpu.driver == "Unakoda" then
                        self.gpu:drawRectangle(x, y, width, height, color)
                    else
                    end
                end
            end
        end,
        DRM = function(x, y, data)
            self:applyLoadDelay()
            if self.gpu then
                if self.gpu then
                    if self.gpu.driver == "Unakoda" then
                        self.gpu:drawImage(x, y, data)
                    else
                    end
                end
            end
        end,
        DLN = function(x, y, x2, y2, color)
            self:applyLoadDelay()
            if self.gpu then
                if self.gpu then
                    if self.gpu.driver == "Unakoda" then
                        self.gpu:drawLine(x, y, x2, y2, color)
                    else
                    end
                end
            end
        end,
        SLEEP = function(s)
            self:applyLoadDelay()
            local start = self.lastTime or love.timer.getTime()
            while (love.timer.getTime() - start) < s do
                coroutine.yield()
            end
        end,

        read = function(addr) self:applyLoadDelay() return self.motherboard:readMemory(addr) end,
        write = function(addr, value) self:applyLoadDelay() return self.motherboard:writeMemory(addr, value) end,
        print = function(...) self:applyLoadDelay() print(...) end,
        pcall = function(...) self:applyLoadDelay() return pcall(...) end
    }

    env.A = function() self:applyLoadDelay() return regs.AX end
    env.X = function() self:applyLoadDelay() return regs.BX end
    env.Y = function() self:applyLoadDelay() return regs.CX end
    env.SR = function() self:applyLoadDelay() return regs.FLAGS end
    env.SP = function() self:applyLoadDelay() return regs.SP end

    return env
end
return function (self)
    local A, X, Y, SR, SP = 0, 0, 0, 0, 128
    local env = {
        LDA = function(v)
            self:applyLoadDelay()
            A = v
        end,
        STA = function(a)
            self:applyLoadDelay()
            self.motherboard:writeMemory(a, A)
        end,
        LDX = function(v)
            self:applyLoadDelay()
            X = v
        end,
        LDY = function(v)
            self:applyLoadDelay()
            Y = v
        end,
        STX = function(a)
            self:applyLoadDelay()
            self.motherboard:writeMemory(a, X)
        end,
        STY = function (a)
            self:applyLoadDelay()
            self.motherboard:writeMemory(a, Y)
        end,
        ADD = function(a, b)
            self:applyLoadDelay()
            return (a or A) + (b or 0)
        end,
        SUB = function(a, b)
            self:applyLoadDelay()
            return (a or A) - (b or 0)
        end,
        MUL = function(a, b)
            self:applyLoadDelay()
            return (a or A) * (b or 1)
        end,
        DIV = function(a, b)
            self:applyLoadDelay()
            return (a or A) / (b or 1)
        end,
        AND = function(a, b)
            self:applyLoadDelay()
            return bit.band(a or A, b or 0)
        end,
        OR = function(a, b)
            self:applyLoadDelay()
            return bit.bor(a or A, b or 0)
        end,
        XOR = function(a, b)
            self:applyLoadDelay()
            return bit.bxor(a or A, b or 0)
        end,
        NOT = function(a)
            self:applyLoadDelay()
            return bit.bnot(a or A)
        end,
        SHL = function(a, b)
            self:applyLoadDelay()
            return bit.lshift(a or A, b or 1)
        end,
        SHR = function(a, b)
            self:applyLoadDelay()
            return bit.rshift(a or A, b or 1)
        end,
        CMP = function(a, b)
            self:applyLoadDelay()
            local result = (a or A) - (b or 0)
            if result == 0 then
                SR = bit.bor(SR, 0x02)
            else
                SR = bit.band(SR, bit.bnot(0x02))
            end
            return result
        end,
        IF = function (condition, callback, elsecallback)
            self:applyLoadDelay()
            if condition then
                if callback then
                    callback()
                end
            else
                if elsecallback then
                    elsecallback()
                end
            end
        end,
        PUSH = function(v)
            self:applyLoadDelay()
            self.motherboard:writeMemory(SP, v or A)
            SP = SP + 1
        end,
        POP = function()
            self:applyLoadDelay()
            SP = SP - 1
            return self.motherboard:readMemory(SP)
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

        A = function() self:applyLoadDelay() return A end,
        X = function() self:applyLoadDelay() return X end,
        Y = function() self:applyLoadDelay() return Y end,
        SR = function() self:applyLoadDelay() return SR end,
        SP = function() self:applyLoadDelay() return SP end,

        NIL = nil,
        TRUE = true,
        FALSE = false,

        read = function(addr) return self.motherboard:readMemory(addr) end,
        write = function(addr, value) return self.motherboard:writeMemory(addr, value) end,
        free = function(addr, count) return self.motherboard:freeMemory(addr, count) end,

        print = function (...) self:applyLoadDelay() print(...) end,
        pcall = function (...) self:applyLoadDelay() return pcall(...) end
    }
    return env
end
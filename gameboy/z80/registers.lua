--!native
local Registers = {}

function Registers.new()
    local registers = {}
    local reg = registers

    reg.a = 0
    reg.b = 0
    reg.c = 0
    reg.d = 0
    reg.e = 0
    reg.flags = { z = false, n = false, h = false, c = false }
    reg.h = 0
    reg.l = 0
    reg.pc = 0
    reg.sp = 0

    reg.f = function()
        local value = 0
        if reg.flags.z then
            value = value + 0x80
        end
        if reg.flags.n then
            value = value + 0x40
        end
        if reg.flags.h then
            value = value + 0x20
        end
        if reg.flags.c then
            value = value + 0x10
        end
        return value
    end

    reg.set_f = function(value)
        reg.flags.z = bit32.band(value, 0x80) ~= 0
        reg.flags.n = bit32.band(value, 0x40) ~= 0
        reg.flags.h = bit32.band(value, 0x20) ~= 0
        reg.flags.c = bit32.band(value, 0x10) ~= 0
    end

    reg.af = function()
        local a = reg.a or 0
        return bit32.lshift(a, 8) + reg.f()
    end

    reg.bc = function()
        local b = reg.b or 0
        local c = reg.c or 0
        return bit32.lshift(b, 8) + c
    end

    reg.de = function()
        local d = reg.d or 0
        local e = reg.e or 0
        return bit32.lshift(d, 8) + e
    end

    reg.hl = function()
        local h = reg.h or 0
        local l = reg.l or 0
        return bit32.lshift(h, 8) + l
    end

    reg.set_bc = function(value)
        reg.b = bit32.rshift(bit32.band(value, 0xFF00), 8)
        reg.c = bit32.band(value, 0xFF)
    end

    reg.set_de = function(value)
        reg.d = bit32.rshift(bit32.band(value, 0xFF00), 8)
        reg.e = bit32.band(value, 0xFF)
    end

    reg.set_hl = function(value)
        reg.h = bit32.rshift(bit32.band(value, 0xFF00), 8)
        reg.l = bit32.band(value, 0xFF)
    end

    return registers
end

return Registers

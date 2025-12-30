--!native

local function apply(opcodes, opcode_cycles, z80, memory)
    local reg = z80.registers
    local flags = reg.flags

    local read_byte = memory.read_byte
    local write_byte = memory.write_byte

    local set_inc_flags = function(value: number)
        -- Handle nil values (can occur during save state loading)
        local v = value or 0
        flags.z = v == 0
        flags.h = v % 0x10 == 0x0
        flags.n = false
    end

    local set_dec_flags = function(value: number)
        -- Handle nil values (can occur during save state loading)
        local v = value or 0
        flags.z = v == 0
        flags.h = v % 0x10 == 0xF
        flags.n = true
    end

    -- inc r
    opcodes[0x04] = function()
        reg.b = bit32.band((reg.b or 0) + 1, 0xFF)
        set_inc_flags(reg.b)
    end
    opcodes[0x0C] = function()
        reg.c = bit32.band((reg.c or 0) + 1, 0xFF)
        set_inc_flags(reg.c)
    end
    opcodes[0x14] = function()
        reg.d = bit32.band((reg.d or 0) + 1, 0xFF)
        set_inc_flags(reg.d)
    end
    opcodes[0x1C] = function()
        reg.e = bit32.band((reg.e or 0) + 1, 0xFF)
        set_inc_flags(reg.e)
    end
    opcodes[0x24] = function()
        reg.h = bit32.band((reg.h or 0) + 1, 0xFF)
        set_inc_flags(reg.h)
    end
    opcodes[0x2C] = function()
        reg.l = bit32.band((reg.l or 0) + 1, 0xFF)
        set_inc_flags(reg.l)
    end
    opcode_cycles[0x34] = 12
    opcodes[0x34] = function()
        write_byte(reg.hl(), bit32.band(read_byte(reg.hl()) + 1, 0xFF))
        set_inc_flags(read_byte(reg.hl()))
    end
    opcodes[0x3C] = function()
        reg.a = bit32.band((reg.a or 0) + 1, 0xFF)
        set_inc_flags(reg.a)
    end

    -- dec r
    opcodes[0x05] = function()
        reg.b = bit32.band((reg.b or 0) - 1, 0xFF)
        set_dec_flags(reg.b)
    end
    opcodes[0x0D] = function()
        reg.c = bit32.band((reg.c or 0) - 1, 0xFF)
        set_dec_flags(reg.c)
    end
    opcodes[0x15] = function()
        reg.d = bit32.band((reg.d or 0) - 1, 0xFF)
        set_dec_flags(reg.d)
    end
    opcodes[0x1D] = function()
        reg.e = bit32.band((reg.e or 0) - 1, 0xFF)
        set_dec_flags(reg.e)
    end
    opcodes[0x25] = function()
        reg.h = bit32.band((reg.h or 0) - 1, 0xFF)
        set_dec_flags(reg.h)
    end
    opcodes[0x2D] = function()
        reg.l = bit32.band((reg.l or 0) - 1, 0xFF)
        set_dec_flags(reg.l)
    end
    opcode_cycles[0x35] = 12
    opcodes[0x35] = function()
        write_byte(reg.hl(), bit32.band(read_byte(reg.hl()) - 1, 0xFF))
        set_dec_flags(read_byte(reg.hl()))
    end
    opcodes[0x3D] = function()
        reg.a = bit32.band((reg.a or 0) - 1, 0xFF)
        set_dec_flags(reg.a)
    end
end

return apply

from binascii import unhexlify
import sys

def make_table():
    table = []
    for n in range(256):
        c = n
        for k in range(8):
            if c & 1 != 0:
                c = 0xedb88320 ^ (c >> 1)
            else:
                c = c >> 1
        table.append(c)
    return table

table = make_table()


def calc_crc_internal(msg):
    table = make_table()
    crc = 0xFF_FF_FF_FF

    for i in range(len(msg)):
        crc = table[(crc ^ msg[i]) & 0xff] ^ (crc >> 8)

    return crc


def calc_crc(msg):
    return calc_crc_internal(msg) ^ 0xFF_FF_FF_FF


def fmh(num, width):
    return "{}'h{}".format(width, hex(num)[2:])


def gen_verilog(table, func_name='crc32_lookup'):
    assert len(table) == 256
    assert all(0 <= x < 2 ** 32 for x in table)

    print('function automatic [31:0] crc32_lookup;'.format(func_name))
    print('  input [7:0] num;')
    print('  begin')
    print('    case(num)')
    for i, num in enumerate(table):
        print("      {}: crc32_lookup = {};".format(fmh(i, 8), fmh(num, 32)))
    print('    endcase')
    print('  end')
    print('endfunction')



data = unhexlify('ffffffffffff00e04c6c242f0806000108000604000100e04c6c242f0a4545010000000000000a454502000000000000000000000000000000000000')
print(hex(calc_crc(data)))

gen_verilog(make_table())



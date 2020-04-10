data = "ffffffffffff00e04c6c242f0806000108000604000100e04c6c242f0a4545010000000000000a454502000000000000000000000000000000000000fe8b0413"

# data = '08 00 27 27 1a d5 52 54 00 12 35 02 08 00 45 00 00 54 1e 49 40 00 40 01 04 50 0a 00 02 02 0a 00 02 0f 00 00 59 d6 0f af 00 01 fd b5 f5 5a 00 00 00 00 e1 95 03 00 00 00 00 00 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 36 37 612d3267'

data = '55555555555555d5' + data.replace(' ', '')
data2 = ''.join([c[1] + c[0] for c in zip(data[::2], data[1::2])])

# print(data)
# print(data2)

for num, char in enumerate(data2):
    print('31\'d%d: tx_nibble=4\'h%c;' % (num, char,))

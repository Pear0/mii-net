data = "55555555555555d5ffffffffffff00e04c6c242f0806000108000604000100e04c6c242f0a4545010000000000000a454502000000000000000000000000000000000000ff8b0413"
data2 = ''.join([c[1] + c[0] for c in zip(data[::2], data[1::2])])

print(data)
print(data2)

for num, char in enumerate(data2):
    print('31\'d%d: tx_nibble=4\'h%c;' % (num, char,))

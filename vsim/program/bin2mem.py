with open("prog.bin", "rb") as f:
    data = f.read()

with open("prog.mem", "w") as f:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        if len(word) < 4:
            word += b'\x00' * (4 - len(word))
        val = int.from_bytes(word, byteorder="little")
        f.write(f"{val:08x}\n")
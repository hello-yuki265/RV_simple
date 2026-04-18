.PHONY: clean

CLEAN_FILES := *.bin *.dump *.elf *.mem

generate: compile
	python3 bin2mem.py
	cp -f prog.mem ../prog.mem

compile: 
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T link.ld -o prog.elf main.s
	riscv64-unknown-elf-objdump -d prog.elf
	riscv64-unknown-elf-objcopy -O binary prog.elf prog.bin

clean:
	$(RM) $(CLEAN_FILES)

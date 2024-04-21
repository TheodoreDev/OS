# Create the OS.bin file ( make OS )
OS: bootSect.bin kernel.bin fileTable.bin calculator.bin
	cat bootSect.bin kernel.bin fileTable.bin calculator.bin > temp.bin;\
	dd if=/dev/zero of=OS.bin bs=512 count=2880;\
	dd if=temp.bin of=OS.bin conv=notrunc;\
	rm temp.bin

# Create boot sector bin file
bootSect.bin:
	fasm ../src/asm/bootSect.asm
	mv ../src/asm/bootSect.bin ./

# Create file table bin file
fileTable.bin:
	fasm ../src/asm/fileTable.asm
	mv ../src/asm/fileTable.bin ./

# Create kernel bin file
kernel.bin:
	fasm ../src/asm/kernel.asm
	mv ../src/asm/kernel.bin ./

# Create calculator bin file
calculator.bin:
	fasm ../src/asm/calculator.asm
	mv ../src/asm/calculator.bin ./

# Run OS through bochs (use 'Make run')
run: OS
	bochs -q

# Clean up all the bin file
clean:
	rm *.bin

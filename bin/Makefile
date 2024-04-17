# Create the OS.bin file ( make OS )
OS: bootSect.bin fileTable.bin kernel.bin
	cat bootSect.bin fileTable.bin kernel.bin > OS.bin

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

# Clean up all the bin file
clean:
	rm *.bin

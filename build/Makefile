# Create the OS.bin file ( make OS )
OS:
	./asm_src.sh;\
	mv ../src/*.bin ../bin;\
	cat ../bin/bootSect.bin ../bin/kernel.bin ../bin/fileTable.bin ../bin/calculator.bin ../bin/editor.bin > ../bin/temp.bin;\
	dd if=/dev/zero of=../bin/OS.bin bs=512 count=2880;\
	dd if=../bin/temp.bin of=../bin/OS.bin conv=notrunc;\
	rm ../bin/*[!OS].bin

# Clean up all the bin file
clean:
	rm -f ../bin/*.bin

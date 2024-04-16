;;; Basic boot sector
;;;

[org 0x7c00]				; 'origin' of Boot code; help make sure adress don't change

mov ah, 0x0e				; int 10/ ah 0x0e BIOS teletype output
mov bx, testString			; moving memory adress at testString into BX reg
jmp printString

printString:
	mov al, [bx]			; move character value at adress in BX into AL
	cmp al, 0
	je end_pgm			; jump if equal (al = 0) to halt label
	int 0x10			; print character in AL
	add bx, 1			; move 1 byte forward/ get next character
	jmp printString			; loop

testString: 
	db "TEST", 0			; 0/null to null terminate

end_pgm:
	jmp $				; keep jumping to here; neverending loop
	times 510-($-$$) db 0		; pad file with 0s until 510th bytes
	dw 0xaa55			; BIOS magic number in 511th and 512th bytes

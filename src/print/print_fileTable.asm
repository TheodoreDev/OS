;;;print_fileTable.asm: prints file table entries to screen
;;;

print_fileTable:
	pusha
	
	mov si, fileTableHeading
	call print_string
	
	;; load file table string
	xor cx, cx					; reset counter for # of byte at current file table entry
	mov ax, 0x1000				; file table loc
	mov es, ax					; ES = 0x1000
	xor bx, bx					; ES:BX = 0x1000:0
	mov ah, 0x0e				; get ready to print screen
	
	mov al, [ES:BX]

fileName_loop:
	mov al, [ES:BX]
	cmp al, 0					; at end of file tab ? or file name null ?
	je end_print_fileTable		;  no more names? at the end of file table ?

	int 0x10					; print char in al to screen
	cmp cx, 9 					; at the end of name ?
	je file_ext
	inc cx						; increment file entry byte counter
	inc bx						; get next byte at file table
	jmp fileName_loop

file_ext:
	mov cx, 3
	call print_blanks_loop

	inc bx
	mov al, [ES:BX]
	int 0x10
	inc bx
	mov al, [ES:BX]
	int 0x10
	inc bx
	mov al, [ES:BX]
	int 0x10

dir_entry_number:
	mov cx, 9
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call print_hex_as_ascii

start_sector_number:
	mov cx, 9
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call print_hex_as_ascii

file_size:
	mov cx, 14
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call print_hex_as_ascii
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10

	inc bx						; get first byte of next file name
	xor cx, cx					; reset counter for next file name
	jmp fileName_loop

end_print_fileTable:
	popa
	ret

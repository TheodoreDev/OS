;;;print_fileTable.asm: prints file table entries to screen
;;;

print_fileTable:
	pusha
	
	mov si, fileTableHeading
	call print_string
	
	;; load file table string
	;; load file table from disk to memory
	mov bx, 100h
	mov es, bx
	xor bx, bx					; ES:BX <- 100h:0000h = 1000h; file table mem location
	xor dx, dx					; DH = head number; DL = drive number
	mov cx, 0006h				; CH = cylinder number; DL = starting sector

try_load:
	mov ax, 0201h				; AH = 02h/int 13h read disk sector; AL = number of sector to read

	int 13h
	jc try_load

	xor cx, cx					; reset counter for # of byte at current file table entry
	mov ax, 100h				; file table loc
	mov ah, 0Eh					; get ready to print screen

fileName_loop:
	mov al, [ES:BX]
	cmp al, 0					; at end of file tab ? or file name null ?
	je end_print_fileTable		;  no more names? at the end of file table ?

	int 0x10					; print char in al to screen
	cmp cx, 9 					; at the end of name ?
	je other_info
	inc cx						; increment file entry byte counter
	inc bx						; get next byte at file table
	jmp fileName_loop

other_info:
	;; file extention
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

	;; directory entry number
	mov cx, 9
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call hex_to_ascii
	int 0x10

	;; starting sector number
	mov cx, 9
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call hex_to_ascii
	int 0x10

	;; file size
	mov cx, 14
	call print_blanks_loop
	
	inc bx
	mov al, [ES:BX]
	call hex_to_ascii
	int 0x10
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

;; print out cx number of space to screen
print_blanks_loop:
	mov ah, 0x0e
	mov al, " "
	int 0x10
	loop print_blanks_loop
	ret

;; Variables/constants
nl equ 0xA, 0xD
fileTableHeading:
	db nl, "----------   ---------   -------   ------------   --------------",\
	nl,"File Name    Extension   Entry #   Start Sector   Size (sectors)",\
	nl,"----------   ---------   -------   ------------   --------------",\
	nl,0

;;; Made by TheodoreDev

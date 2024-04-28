;;; editor.asm: text editor with "modes"
;;;

;; contants
ENDPGM equ '?'
ENDINPUT equ '$'
VIDMEM equ 0B800h

init:
	;; Clear the screen
	call resetTextScreen

	;; Write keybinds at the bottom of screen
	mov ax, VIDMEM
	mov es, ax
	mov word di, 0F00h				; ES:DI <- 0B00h:80*2*24
	
	mov si, controlsString
	mov cx, 33						; number of byte to move
	cld								; clear direction flag (increment operands)

	rep movsw						; mov [di], [si] and increment both
	
	;; Restore data/extra segments
	mov ax, 8000h
	mov es, ax

	;; User input and print to screen
	xor cx, cx						; reset byte counter
	mov di, hex_code				; di points to memory address of hex code

get_next_hex_char:
	xor ax, ax
	int 16h							; get keystroke
	mov ah, 0Eh
	cmp al, ENDINPUT				; at the end of user input
	je execute_input
	cmp al, ENDPGM					; end program, exit back to kernel
	je end_editor
	
	int 10h							; print out input char
	call ascii_to_hex

	inc cx							; increment byte counter
	cmp cx, 2 						; 2 ascii bytes = 1 hex byte
	je put_hex_byte         
	mov [hex_byte], al				; put input into hex byte memory area
	
return_from_hex:
	jmp get_next_hex_char

;; Convert to valid machine code & run
execute_input:
	mov byte [di], 0C3h 			; C3 hex = near return x86 instruction
	jmp hex_code					; jump to hex code memory location to run
	
	jmp init						; reset for next input

put_hex_byte:
	rol byte [hex_byte], 4			; move digit 4 bits to the left, make room for 2nd digit
	or byte [hex_byte], al			; move 2nd ascii byte/hex digit into memory
	mov al, [hex_byte]
	stosb							; put hex byte(2 hex digits) into hex code memory area and inc di
	xor cx, cx 						; reset byte counter
	mov al, ' '						; print space to screen
	int 10h
	jmp return_from_hex

ascii_to_hex:
	cmp al, '9'						; is input ascii '0' - '9'
	jle get_hex_num
	sub al, 37h						; convert to hex

return_from_hex_num:
	ret

get_hex_num:
	sub al, 30h						; convert to hex num
	jmp return_from_hex_num

end_editor:
	mov ax, 0x2000
	mov es, ax
	xor bx, bx						; ES:BX -> 0x2000:0x0000

	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	jmp 0x2000:0x0000				; far jmp back to kernel

;; include files
include "../print/print_string.asm"
include "../screen/set_text_screen.asm"

;; variables
testString:
	db "Testing", 0
controlsString:   
	db '$',17h,' ',17h,'=',17h,' ',17h,'R',17h,'u',17h,'n',17h,\
	' ',17h,'c',17h,'o',17h,'d',17h,'e',17h,' ',17h,'?',17h,' ',\
	17h,'=',17h,' ',17h,'R',17h,'e',17h,'t',17h,'u',17h,'r',17h,\
	'n',17h,' ',17h,'t',17h,'o',17h,' ',17h,'k',17h,'e',17h,'r',\
	17h,'n',17h,'e',17h,'l',17h
hex_byte:
	db 00h							; 1 byte/2 hex digits
hex_code:
	times 255 db 0

;; Sector padding
times 1024-($-$$) db 0

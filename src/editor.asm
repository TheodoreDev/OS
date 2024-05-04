;;; editor.asm: text editor with "modes"
;;;

;; contants
ENDPGM equ '?'
ENDINPUT equ '$'
VIDMEM equ 0B800h

init:
	;; Clear the screen
	call clear_screen_text_mode

	;; Write keybinds at the bottom of screen
	mov ax, VIDMEM
	mov es, ax
	mov word di, 0F00h				; ES:DI <- 0B00h:80*2*24
	
	mov si, controlsString
	mov cx, 52						; number of byte to move
	cld								; clear direction flag (increment operands)

	mov al, byte [text_color]
	.loop:
	movsb							; mov [di], [si] and increment both
	stosb							; store character attribute byte (txt color)
	loop .loop
	
	;; Restore data/extra segments
	mov ax, 800h
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
	call hex_code					; jump to hex code memory location to run
	
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
	mov ax, 0x200
	mov es, ax
	xor bx, bx						; ES:BX -> 0x2000:0x0000

	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	jmp 200h:0000h					; far jmp back to kernel

;; include files
include "../include/print/print_string.inc"
include "../include/screen/clear_screen_text_mode.inc"
include "../include/disk/load_file.inc"
include "../include/disk/save_file.inc"

;; variables
testString:
	db "Testing", 0
controlsString:   
	db " $ = Run code ; ? = Return to kernel ; S = save file"
controlsString_length equ $-controlsString
new_o_current_string:
	db "[C]reate new file or [L]oad current file?"
choose_filetype_string:
	db "[B]inary/hex file or [O]ther file type"
hex_byte:
	db 00h							; 1 byte/2 hex digits
hex_code:
	times 255 db 0
text_color:
	db 17h

;; Sector padding
times 1536-($-$$) db 0

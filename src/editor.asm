;;; editor.asm: text editor with "modes"
;;;

;; contants
ENDPGM equ '?'
RUNINPUT equ '$'
SAVEPGM equ 'S'
CREATENEW equ 'C'
LOADEXIST equ 'L'
BINFILE equ 'B'
OTHERFILE equ 'O'
VIDMEM equ 0B800h

init:
	;; Clear the screen
	call clear_screen_text_mode

	mov si, new_o_current_string
	call print_string
	xor ah, ah
	int 16h
	cmp al, CREATENEW				; Create new file
	je create_new_file
	cmp al, LOADEXIST				; load an existing file
	je load_existing_file

create_new_file:
	call clear_screen_text_mode
	mov si, choose_filetype_string
	call print_string
	xor ah, ah
	int 16h
	mov byte [editor_filesize], 0	; Reset filesize counter
	cmp al, BINFILE					; binary file
	je hex_editor
	cmp al, OTHERFILE				; other file
	je text_editor

load_existing_file:
;; TODO

text_editor:
;; TODO

hex_editor:
	call clear_screen_text_mode

	;; Write keybinds at the bottom of screen
	mov si, controlsString
	mov cx, 52						; number of byte to move
	call write_bottom_screen_msg
	
	;; Restore data/extra segments
	mov ax, 800h
	mov es, ax

	;; User input and print to screen
	xor cx, cx						; reset byte counter
	mov ax, 1000h
	mov es, ax
	xor di, di						; ES:DI <- 1000h:0000 = 10000h

get_next_hex_char:
	xor ax, ax
	int 16h							; get keystroke
	mov ah, 0Eh
	cmp al, RUNINPUT				; at the end of user input
	je execute_input
	cmp al, ENDPGM					; end program, exit back to kernel
	je end_editor
	cmp al, SAVEPGM					; save your program
	je save_program
	
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
	mov byte [es:di], 0CBh 			; CB hex = far return x86 instruction
	xor di, di
	call 1000h:0000h				; jump to hex code memory location to run
	
	jmp hex_editor						; reset for next input

put_hex_byte:
	rol byte [hex_byte], 4			; move digit 4 bits to the left, make room for 2nd digit
	or byte [hex_byte], al			; move 2nd ascii byte/hex digit into memory
	mov al, [hex_byte]
	stosb							; put hex byte(2 hex digits) into hex code memory area and inc di
	inc byte [editor_filesize]		; Increment filesize counter
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

save_program:
	;; Have user enter file name for new file
	call clear_screen_text_mode
	mov si, file_name_string
	call print_string

	;; Restore extra segment
	mov ax, 800h
	mov es, ax

	;; Save file type
	mov di, editor_filetype
	mov al, 'b'
	stosb
	mov al, 'i'
	stosb
	mov al, 'n'
	stosb

	mov di, editor_filename
	mov cx, 10

.input_filename_loop:
	xor ah, ah						; Get keystroke
	int 16h
	stosb							; store char to filename variable
	mov ah, 0Eh
	int 0x10
	loop .input_filename_loop

	;; Call save_file function
	push word editor_filename		; 1 params - filename
	push word editor_filetype		; 2 params - filetype
	push word 0001h					; 3 params - filesize
	push word 1000h					; 4 params - segment memory address
	push word 0000h					; 5 params - offset memory adress

	call save_file
	add sp, 10						; Restore stack pointer after returning
	cmp ax, 0
	jne save_file_error				; Error occured
	jmp save_file_success

save_file_error:
	mov si, save_error_string
	mov cx, 24
	call write_bottom_screen_msg

	xor ax, ax
	int 16h

save_file_success:
	;; Return to normal hex editor
	jmp get_next_hex_char

write_bottom_screen_msg:
	;; Message to write at the bottom of the screen
	mov ax, VIDMEM
	mov es, ax
	mov word di, 0F00h				; ES:DI <- 0B00h:80*2*24

	mov al, byte [text_color]
	.loop:
	movsb							; mov [di], [si] and increment both
	stosb							; store character attribute byte (txt color)
	loop .loop
	ret

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
	db "[C]reate new file or [L]oad existing file?", 0
choose_filetype_string:
	db "[B]inary/hex file or [O]ther file type", 0
file_name_string:
	db "Enter file name: ", 0
save_error_string:
	db "Save file error occured", 0

editor_filename:
	times 10 db 0
editor_filetype:
	times 3 db 0
editor_filesize:
	db 0
hex_byte:
	db 00h							; 1 byte/2 hex digits
text_color:
	db 17h

;; Sector padding
times 1536-($-$$) db 0

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
LEFTARROW equ 4Bh
RIGHTARROW equ 4Dh
UPARROW equ 48h
DOWNARROW equ 50h
BACKSPACE equ 08h
ESC equ 01h

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
	mov word [editor_filesize], 0	; Reset filesize counter
	cmp al, BINFILE					; binary file
	je new_file_hex
	cmp al, OTHERFILE				; other file
	je new_file_txt

load_existing_file:
	call print_fileTable
	mov si, choose_file_msg
	call print_string

	;; Restore extra segment
	mov ax, 800h
	mov es, ax

	;; file name of the pgm to load
	call input_file_name

	;; load file from input file name
	push word editor_filename		; 1 params - filename
	push word 1000h					; 2 params - segment to load to
	push word 0000h					; 3 params - offset to load to
	call load_file

	add sp, 6						; Reset the stack
	
	cmp ax, 0						; Error check
	jne load_file_error				; Error occured
	jmp load_file_success

load_file_error:
	mov si, load_error_string
	mov cx, 24
	call write_bottom_screen_msg

	xor ax, ax
	int 16h
	call clear_screen_text_mode
	jmp load_existing_file

load_file_success:
	;; Restore extra segment
	mov ax, 800h
	mov es, ax

	;; Get file type from bx
	mov di, editor_filetype
	mov al, [bx]
	stosb
	mov al, [bx+1]
	stosb
	mov al, [bx+2]
	stosb

	;; Go to editor depending on file type (hex/other)
	mov si, bx
	mov di, extBin
	mov cx, 3
	rep cmpsb						; Check the file extention
	je load_file_hex				; .bin : gotto hex editor
	jmp load_file_txt				; otherwise : gotto text editor

new_file_hex:
	call clear_screen_text_mode
	;; get fileext (.bin)
	mov ax, 800h
	mov es, ax						; reset ex to program location (8000h)

	mov di, editor_filetype
	mov al, 'b'
	stosb
	mov al, 'i'
	stosb
	mov al, 'n'
	stosb
	;; Write keybinds at the bottom of screen
	mov si, control_str_hex
	mov cx, 52						; number of byte to write
	call fill_out_editor_hud

	jmp hex_editor

load_file_hex:
	call clear_screen_text_mode
	mov ax, 1000h
	mov es, ax
	xor di, di						; ES:DI <- 1000h:0000 = 10000h

	mov cx, 512						; TODO: actual file size
	mov ah, 0Eh

	.loop:
	mov al, [ES:DI]					; Read hex byte from file location
	ror al, 4						; Get 1sr nibble into al
	and al, 00001111b
	call hex_to_ascii
	int 0x10

	mov al, [ES:DI]
	and al, 00001111b				; Get 2nd nibble into al
	call hex_to_ascii
	int 0x10

	mov al, ' '						; print a space
	int 0x10
	inc di
	loop .loop

	dec di							; Fix off by one
	mov word [save_di], di			; save di first

	;; Write keybinds at the bottom of screen
	mov si, control_str_hex
	mov cx, 44						; number of byte to write
	call fill_out_editor_hud

	mov ax, 1000h
	mov es, ax						; reset to file location
	mov di, [save_di]
	jmp get_next_hex_char			; Go to hex editor

new_file_txt:
	call clear_screen_text_mode
	;; get fileext (.txt)
	mov ax, 800h
	mov es, ax						; reset ex to program location (8000h)

	mov di, editor_filetype
	mov al, 't'
	stosb
	mov al, 'x'
	stosb
	mov al, 't'
	stosb
	;; Write keybinds at the bottom of screen
	mov si, control_str_txt
	mov cx, 44						; number of byte to write
	call fill_out_editor_hud

	jmp text_editor

load_file_txt:
	call clear_screen_text_mode
	mov ax, 1000h
	mov es, ax
	xor di, di						; ES:DI <- 1000h:0000 = 10000h

	mov cx, 512						; TODO: actual file size
	mov ah, 0Eh

	.loop:
	mov al, [ES:DI]					; Read hex byte from file location
	int 0x10
	inc di
	loop .loop

	dec di							; Fix off by one
	mov word [save_di], di			; save di first

	;; Write keybinds at the bottom of screen
	mov si, control_str_txt
	mov cx, 44						; number of byte to write
	call fill_out_editor_hud

	mov ax, 1000h
	mov es, ax						; reset to file location
	mov di, [save_di]

	jmp text_editor					; Gotto txt editor

text_editor:
	get_next_txt_char:
		xor ah, ah
		int 16h							; get keystroke
		mov byte [save_scancode], ah
		cmp ah, 0Eh

		;; Check for text editor keybinds
		cmp byte [save_scancode], ESC	; Escape key
		je end_editor

		;; Print out user input char to screen
		xor ah, ah
		push word ax					; char to print
		push word [cursor_y]
		push word [cursor_x]
		call print_char_text_mode

		add sp, 6

		;; Move cursor foreward
		inc word [cursor_x]
		push word [cursor_y]
		push word [cursor_x]
		call move_cursor

		add sp, 4

		;; TODO : backspace + arrow keys

		jmp get_next_txt_char

hex_editor:
	;; User input and print to screen
	xor cx, cx							; reset byte counter
	mov ax, 1000h
	mov es, ax
	xor di, di							; ES:DI <- 1000h:0000 = 10000h

	;; Reset cursor x/y
	mov word [cursor_x], 0
	mov word [cursor_y], 0

	get_next_hex_char:
		xor ax, ax
		int 16h							; get keystroke
		mov byte [save_scancode], ah
		mov ah, 0Eh

		;; Check hex editor keybinds
		cmp al, RUNINPUT				; at the end of user input
		je execute_input
		cmp al, ENDPGM					; end program, exit back to kernel
		je end_editor
		cmp al, SAVEPGM					; save your program
		je save_program

		;; Check for backspace
		cmp al, BACKSPACE				; backspace
		jne check_arrow_keys

		cmp word [cursor_x], 3			; at the beggining of the line
		jl get_next_hex_char

		;; del first nibble
		push word 0020h					; space ' ' in ascii
		push word [cursor_y]
		push word [cursor_x]
		call print_char_text_mode

		add sp, 6						; restore stack

		;; del second nibble
		push word 0020h					; space ' ' in ascii
		push word [cursor_y]
		inc word [cursor_x]				; second nibble of hex byte
		push word [cursor_x]
		call print_char_text_mode

		add sp, 6						; restore stack

		;; Move cursor 1 full hex byte left
		sub word [cursor_x], 4

		push word [cursor_y]
		push word [cursor_x]
		call move_cursor
		add sp, 4						; restore the stack after call

		mov [ES:DI], byte 00h
		dec di							; Move file data to next byte
		jmp get_next_hex_char

	;; Check arrow keys
	check_arrow_keys:
		cmp byte [save_scancode], LEFTARROW		; Left arrow
		je left_arrow_pressed
		cmp byte [save_scancode], RIGHTARROW	; Right arrow
		je right_arrow_pressed
		cmp byte [save_scancode], UPARROW		; Up arrow
		je up_arrow_pressed
		cmp byte [save_scancode], DOWNARROW		; Down arrow
		je down_arrow_pressed

		jmp check_valid_hex

	left_arrow_pressed:
		cmp byte [cursor_x], 3			; at the beggining of the line
		jl get_next_hex_char
		sub byte [cursor_x], 3

		push word [cursor_y]
		push word [cursor_x]
		call move_cursor
		add sp, 4						; restore the stack after call

		dec di							; Move file data to previous byte
		jmp get_next_hex_char

	right_arrow_pressed:
		cmp byte [cursor_x], 75			; at the end of the line
		jg get_next_hex_char
		add byte [cursor_x], 3

		push word [cursor_y]
		push word [cursor_x]
		call move_cursor
		add sp, 4						; restore the stack after call

		inc di							; Move file data to next byte
		jmp get_next_hex_char

	up_arrow_pressed:
		;; TODO

	down_arrow_pressed:
		;; TODO


	;; Prevent entering a non-hex digit
	check_valid_hex:
		cmp al, '0'
		jl get_next_hex_char			; skip input char
		cmp al, '9'
		jle convert_input

	check_if_athruf_upercase:
		cmp al, 'A'
		jl get_next_hex_char			; skip input char
		cmp al, 'F'
		jle convert_input

	check_if_athruf_lowercase:
		cmp al, 'a'
		jl get_next_hex_char			; skip input char
		cmp al, 'f'
		jg get_next_hex_char			; skip input char

		sub al, 20h						; Convert lowercase to uper

	convert_input:
		int 10h							; print out input char
		inc byte [cursor_x]
		call ascii_to_hex

		inc cx							; increment byte counter
		cmp cx, 2 						; 2 ascii bytes = 1 hex byte
		je put_hex_byte         
		mov [hex_byte], al				; put input into hex byte memory area

	return_from_hex:
		jmp get_next_hex_char

	;; Convert to valid machine code & run
	execute_input:
		mov di, word [editor_filesize]	; di point to end of file
		mov byte [ES:DI], 0CBh 			; CB hex = far return x86 instruction
		xor di, di
		call 1000h:0000h				; jump to hex code memory location to run

		jmp hex_editor					; reset for next input

	put_hex_byte:
		rol byte [hex_byte], 4			; move digit 4 bits to the left, make room for 2nd digit
		or byte [hex_byte], al			; move 2nd ascii byte/hex digit into memory
		mov al, [hex_byte]
		stosb							; put hex byte(2 hex digits) into hex code memory area and inc di
		inc word [editor_filesize]		; Increment filesize counter
		xor cx, cx 						; reset byte counter
		mov al, ' '						; print space to screen
		int 10h
		inc byte [cursor_x]

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
		;; Fill out rest of sector with data if not already
		xor dx, dx
		mov ax, word [editor_filesize]
		mov bx, 512
		div bx							; ax : quotient ; dx : remainder
		cmp ax, 0
		je check_sector
		imul cx, ax, 512				; Otherwise number of sector already filled
		cmp dx, 0
		je enter_filename				; No need to fill
		jmp fill_out_sector				; fill out rest of sector with 0

	check_sector:
		cmp dx, 0
		jne fill_out_sector				; file not empty, fill out a part of sector

		;; Otherwise, fill out the whole sector
		mov cx, 512
		xor al, al
		rep stosb
		jmp enter_filename

	fill_out_sector:
		mov cx, 512
		sub cx, dx
		xor al, al
		rep stosb

	enter_filename:
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

		;; file name to save the pgm as
		call input_file_name

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
		call clear_screen_text_mode
		mov si, save_error_string
		mov cx, 24
		call write_bottom_screen_msg

		xor ax, ax
		int 16h

	save_file_success:
		call clear_screen_text_mode
		;; Write keybinds at the bottom of screen
		mov si, control_str_hex
		mov cx, 52						; number of byte to write
		call fill_out_editor_hud
		jmp get_next_hex_char			; Return to normal hex editor

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

input_file_name:
	mov di, editor_filename
	mov cx, 10

.input_filename_loop:
	xor ah, ah						; Get keystroke
	int 16h
	stosb							; store char to filename variable
	mov ah, 0Eh
	int 0x10
	loop .input_filename_loop

	ret

fill_out_editor_hud:
	;; Fill string variable with msg to write
	mov ax, 800h
	mov es, ax
	mov di, editor_hud
	rep movsb

	mov al, ' '						; append filetype to string
	stosb
	stosb
	mov al, '['
	stosb
	mov al, '.'
	stosb
	mov si, editor_filetype
	mov cx, 3
	rep movsb
	mov al, ']'
	stosb

	mov si, editor_hud
	mov cx, 80
	call write_bottom_screen_msg
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
include "../include/screen/move_cursor.inc"
include "../include/print/print_fileTable.inc"
include "../include/print/print_char_text_mode.inc"
include "../include/disk/load_file.inc"
include "../include/disk/save_file.inc"
include "../include/type_conversions/hex_to_ascii.inc"

;; variables
editor_hud:
	times 80 db 0
control_str_hex:
	db " $ = Run code ; ? = Return to kernel ; S = save file"
control_str_txt:
	db " ESC = Return to kernel ; CTRL+W = save file"
new_o_current_string:
	db "[C]reate new file or [L]oad existing file?", 0
choose_filetype_string:
	db "[B]inary/hex file or [O]ther file type", 0
file_name_string:
	db "Enter file name: ", 0
save_error_string:
	db "Save file error occured", 0
load_error_string:
	db "Load file error occured", 0
choose_file_msg:
	db "Choose file to load:", 0

editor_filename:
	times 10 db 0
editor_filetype:
	times 3 db 0
editor_filesize:
	dw 0

extBin:
	db "bin"

hex_byte:
	db 00h							; 1 byte/2 hex digits
text_color:
	db 17h
save_di:
	dw 0
save_scancode:
	db 0
cursor_x:
	dw 0
cursor_y:
	dw 0

;; Sector padding
times 2560-($-$$) db 0

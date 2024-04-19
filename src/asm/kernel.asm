;;;Kernel.asm: Basic kernel loaded from bootsector
;;;

main_menu:
	;; Set window and clear it
	call resetTextScreen

	;; print screen heading and menu options
	mov si,	startMessage		; moving memory adress at testString into BX reg
	call print_string

;; Get user input, print to screen & choose menu opt or run prog
get_input:
	mov di, cmdString		; di now pointing to cmdString

command_loop:
	mov ax, 0x00
	int 0x16			; BIOS int get keystroke

	mov ah, 0x0e
	cmp al, 0xD			; did user press 'enter' key?
	je run_command
	int 0x10			; print input char to screen
	mov [di], al			; store input char to string
	inc di				; go to next byte at di
	jmp command_loop		; loop for next char from user

run_command:
	mov byte [di], 0		; null terminate cmdString from di
	mov al, [cmdString]
	cmp al, "F"			; file table command
	je file_browser
	cmp al, "R"			; warm reboot command
	je reboot
	cmp al, "P"			; print reg command
	je print_registers_values
	cmp al, "G"			; graphic mode test command
	je graphics_test
	cmp al, "N"			; end our current program
	je end_program
	mov si, failure			; command not found
	call print_string
	jmp get_input

;; menu F) File Browser
file_browser:
	;; Set window and clear it
	call resetTextScreen

	mov si, fileTableHeading
	call print_string
	
	;; load file table string
	xor cx, cx			; reset counter for # chars in file name
	mov ax, 0x1000			; file table loc
	mov es, ax			; ES = 0x1000
	xor bx, bx			; ES:BX = 0x1000:0
	mov ah, 0x0e			; get ready to print screen

fileTable_loop:
	inc bx
	mov al, [ES:BX]
	cmp al, "}"			; at end of file tab ?
	je get_program_name
	cmp al, "-"			; at sector number of element ?
	je sectorNumber_loop
	cmp al, ","			; between table elements
	je next_element
	inc cx				; increment counter
	int 0x10
	jmp fileTable_loop

sectorNumber_loop:
	cmp cx, 21
	je fileTable_loop
	mov al, " "
	int 0x10
	inc cx
	jmp sectorNumber_loop

next_element:
	xor cx, cx			; reset counter
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10
	jmp fileTable_loop

get_program_name:
	mov ah, 0x0e
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10
	mov di, cmdString		; di now pointing to cmdString
	mov byte [cmdLength], 0		; reset counter

program_name_loop:
	mov ax, 0x00
	int 0x16			; BIOS int get keystroke

	mov ah, 0x0e
	cmp al, 0xD			; did user press 'enter' key?
	je start_search

	inc byte [cmdLength]		; add to counter
	mov [di], al			; store input char to command string
	inc di				; go to next byte at di
	int 0x10			; print input char to screen
	jmp program_name_loop		; loop for next char from user

start_search:
	mov di, cmdString		; reset di, points to command string
	xor bx, bx			; reset ES:BX to point to beginning of file table

check_next_char_pgm:
	mov al, [ES:BX]			; get file table char
	cmp al, "}"			; at the end of the file table ?
	je pgm_not_found		; if yes, pgm not found

	cmp al, [di]			; does user input match file table char ?
	je start_compare_pgm

	inc bx				; get next char in file table
	jmp check_next_char_pgm		; check loop

start_compare_pgm:
	push bx				; save file table position
	mov byte cl, [cmdLength]

compare_pgm_loop:
	mov al, [ES:BX]			; get file table char
	inc bx				; next byte in input/filetable
	cmp al, [di]			; does input match filetable char
	jne restart_search		; if not, search again from here

	dec cl				; decrement length counter
	jz found_pgm			; counter = 0, program found
	inc di				; go to next byte of input
	jmp compare_pgm_loop

restart_search:
	mov di, cmdString		; reset to start of user input
	pop bx				; restore file table position
	inc bx				; go to next char in file table
	jmp check_next_char_pgm		; start checking again

pgm_not_found:
	mov si, pgmNotFoundString	; program not found
	call print_string
	mov ah, 0x00			; get keystroke
	int 0x16
	mov ah, 0x0e
	int 0x10
	cmp al, "Y"
	je file_browser			; reload file browser
	jmp fileTable_end		; go back to main menu

found_pgm:
	inc bx
	mov cl, 10			; use to get sector number
	xor al, al			; reste al to 0

next_sector_number:
	mov dl, [ES:BX]			; checking next byte of file table
	inc bx
	cmp dl, ","			; at the end of sector number
	je load_pgm			; load pgm from that sector
	cmp dl, 48			; check if al in '0'-'9' in ascii
	jl sector_not_found		; before '0', not a number
	cmp dl, 57
	jg sector_not_found		; after '9', not a number
	sub dl, 48			; convert ascii char to integer
	mul cl				; al * cl (al * 10), result in AH/AL (AX)
	add al, dl			; al = al + dl
	jmp next_sector_number

sector_not_found:
	mov si, sectorNotFound		; pgm not found in file table
	call print_string
	mov ah, 0x00			; get keystroke
	int 0x16
	mov ah, 0x0e
	int 0x10
	cmp al, "Y"
	je file_browser			; go back to file browser
	jmp fileTable_end		; go back to main menu

load_pgm:
	mov cl, al			; cl = sector number to start loading at

	mov ah, 0x00			; int 13h ah 0 = reset disk sys
	mov dl, 0x00
	int 0x13

	mov ax, 0x8000			; memory location to load pgm to
	mov es, ax
	xor bx, bx			; ES:BX -> 0x8000:0x0000

	mov ah, 0x02			; int 13 ah 02 = read disk sectors to memory
	mov al, 0x01			; number of sector to read
	mov ch, 0x00			; track number
	mov dh, 0x00			; head number
	mov dl, 0x00			; drive number

	int 0x13
	jnc pgm_loaded			; carry flag not set, succes

	mov si, pgmNotLoaded		; pgm not loaded correctly, error
	call print_string
	mov ah, 0x00			; get keystroke
	int 0x16
	jmp file_browser		; go back to file browser

pgm_loaded:
	mov ax, 0x8000			; pgm loaded, set segment reg to location
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	jmp 0x8000:0x0000		; far jmp to pgm

fileTable_end:
	mov si, goBackMsg		; show go back msg
	call print_string
	mov ah, 0x00			; get keystroke
	int 0x16
	jmp main_menu			; go back to main menu

;; menu R) Reboot
reboot:
	jmp 0xFFFF:0x0000

;; menu P) Print register values
print_registers_values:
	;; Set window and clear it
	call resetTextScreen

	mov si, printRegHeading
	call print_string

	call print_registers

	mov si, goBackMsg		; show go back message
	call print_string
	mov ah, 0x00			; get key stroke
	int 0x16
	jmp main_menu			; go back to main menu

graphics_test:
	;; Set window and clear it (gfx mode)
	call resetGraphicsScreen

	;; Test square
	mov ah, 0x0C			; write gfx px
	mov al, 0x01			; blue
	mov bh, 0x00			; page number
	
	;; Starting px of square
	mov cx, 100			; colomn number
	mov dx, 100			; row number
	int 0x10

;; px for colomns
squareColLoop:
	inc cx
	int 0x10
	cmp cx, 150
	jne squareColLoop

	;; Go down for one row
	inc dx
	mov cx, 99
	cmp dx, 150
	jne squareColLoop		; pixels for next row

	mov ah, 0x00			; get key stroke
	int 0x16
	jmp main_menu			; go back to main menu

;; menu N) End program
end_program:
	cli				; clear interrupts
	hlt				; halt the cpu

;; Include other file(s)
include "../print/print_string.asm"
include "../print/print_hex.asm"
include "../print/print_registers.asm"
include "../screen/set_text_screen.asm"
include "../screen/set_graphics_screen.asm"

startMessage:
        db "--------------------------------", 0xA, 0xD,\
	"Kernel Booted, Welcome to TedOS.", 0xA, 0xD,\
	"--------------------------------", 0xA, 0xD, 0xA, 0xD,\
	"F) File Browser", 0xA, 0xD,\
	"R) Reboot", 0xA, 0xD,\
	"P) Print Register Values", 0xA, 0xD,\
	"G) Graphics Mode Test", 0xA, 0xD, 0
success:
	db 0xA, 0xD, "Command/Program found !", 0xA, 0xD, 0
failure:
	db 0xA, 0xD, "Command not found :(", 0xA, 0xD, 0
fileTableHeading:
	db "------------         ------", 0xA, 0xD,\
	"File/Program         Sector", 0xA, 0xD,\
	"------------         ------", 0xA, 0xD, 0
printRegHeading:
	db "--------  ------------", 0xA, 0xD,\
	"Register  Mem Location", 0xA, 0xD,\
	"--------  ------------", 0xA, 0xD, 0
pgmNotFoundString:
	db 0xA, 0xD, "Program not found, try again ? (Y)", 0xA, 0xD, 0
sectorNotFound:
	db 0xA, 0xD, "Sector not found, try again ? (Y)", 0xA, 0xD, 0
pgmNotLoaded:
	db 0xA, 0xD, "Program not loaded correctly !",\
	0xA, 0xD, "Press any key to go back to file browser ...", 0xA, 0xD, 0
cmdLength:
	db 0
goBackMsg:mov al, 0xA
	db 0xA, 0xD, 0xA, 0xD, "----------------------------",\
	0xA, 0xD, "Press any key to go back ...", 0
dbgTest:
	db "Test", 0
cmdString:
	db ""

;; Boot Padding magic
times 1536-($-$$) db 0			; pad file with 0s until 1536th bytes

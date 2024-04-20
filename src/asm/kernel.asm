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
	mov si, prompt
	call print_string
	xor cx, cx					; reset byte counter of input
	mov si, cmdString			; di now pointing to cmdString

	mov ax, 0x2000				; reset ES & DS segments to kernel area
	mov es, ax
	mov ds, ax

command_loop:
	xor ax, ax
	int 0x16					; BIOS int get keystroke

	mov ah, 0x0e
	cmp al, 0xD					; did user press 'enter' key?
	je run_command
	
	int 0x10					; print input char to screen
	mov [si], al				; store input char to string
	inc cx						; increment byte counter of input
	inc si						; go to next byte at di
	jmp command_loop			;loop for next character from user

run_command:
	cmp cx, 0
	je input_not_found			; handle empty input
	
	mov byte [si], 0			; null terminate cmdString from di
	mov si, cmdString			; reset di to point to start of user input

check_commands:
	push cx
	mov di, cmdDir				; file table command
	repe cmpsb
	je file_browser
	
	pop cx						; restore cx from the stack
	push cx
	mov di, cmdReboot			; warm reboot command
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je reboot
	
	pop cx						; restore cx from the stack
	push cx
	mov di, cmdPrtreg			; print reg command
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je print_registers_values
	
	pop cx						; restore cx from the stack
	push cx
	mov di, cmdGfx				; graphic mode test command
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je graphics_test
	
	pop cx						; restore cx from the stack
	push cx
	mov di, cmdHalt				; halt the CPU
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je end_program
	
	pop cx						; restore cx from the stack

check_files:

input_not_found:
	mov si, failMsg				; command not found
	call print_string
	jmp get_input

;; menu F) File Browser
file_browser:
	;; Set window and clear it
	call resetTextScreen

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
	je get_program_name			; no more names? at the end of file table ?

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

get_program_name:
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10
	mov di, cmdString			; di now pointing to cmdString
	mov byte [cmdLength], 0		; reset counter

program_name_loop:
	mov ax, 0x00
	int 0x16					; BIOS int get keystroke

	mov ah, 0x0e
	cmp al, 0xD					; did user press 'enter' key?
	je start_search

	inc byte [cmdLength]		; add to counter
	mov [di], al				; store input char to command string
	inc di						; go to next byte at di
	int 0x10					; print input char to screen
	jmp program_name_loop		; loop for next char from user

start_search:
	mov di, cmdString			; reset di, points to command string
	xor bx, bx					; reset ES:BX to point to beginning of file table

check_next_char_pgm:
	mov al, [ES:BX]				; get file table char
	cmp al, 0 					; at the end of the file table ?
	je pgm_not_found			; if yes, pgm not found

	cmp al, [di]				; does user input match file table char ?
	je start_compare_pgm

	add bx, 16					; get next char in file table
	jmp check_next_char_pgm		; check loop

start_compare_pgm:
	push bx						; save file table position
	mov byte cl, [cmdLength]

compare_pgm_loop:
	mov al, [ES:BX]				; get file table char
	inc bx						; next byte in input/filetable
	cmp al, [di]				; does input match filetable char
	jne restart_search			; if not, search again from here

	dec cl						; decrement length counter
	jz found_pgm				; counter = 0, program found
	inc di						; go to next byte of input
	jmp compare_pgm_loop

restart_search:
	mov di, cmdString			; reset to start of user input
	pop bx						; restore file table position
	inc bx						; go to next char in file table
	jmp check_next_char_pgm		; start checking again

pgm_not_found:
	mov si, pgmNotFoundString	; program not found
	call print_string
	mov ah, 0x00				; get keystroke
	int 0x16
	mov ah, 0x0e
	int 0x10
	cmp al, "Y"
	je file_browser				; reload file browser
	jmp fileTable_end			; go back to main menu

;; Read disk sector of pgm to memory and execute it by far jmp
found_pgm:
	add bx, 4					; go to starting sector of user input
	mov cl, [ES:BX]				; use to get sector number
	inc bx
	mov bl, [ES:BX]				; file size in sector / number of sector to read

	xor ax, ax					; reste ax to 0
	mov dl, 0x00
	int 0x13					; int 13h ah 0 = reset disk sys

	mov ax, 0x8000				; memory location to load pgm to
	mov es, ax
	mov al, bl 					; number of sector to read
	xor bx, bx					; ES:BX -> 0x8000:0x0000

	mov ah, 0x02				; int 13 ah 02 = read disk sectors to memory
	mov ch, 0x00				; track number
	mov dh, 0x00				; head number
	mov dl, 0x00				; drive number

	int 0x13
	jnc pgm_loaded				; carry flag not set, succes

	mov si, pgmNotLoaded		; pgm not loaded correctly, error
	call print_string
	mov ah, 0x00				; get keystroke
	int 0x16
	jmp file_browser			; go back to file browser

pgm_loaded:
	mov ax, 0x8000				; pgm loaded, set segment reg to location
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	jmp 0x8000:0x0000			; far jmp to pgm

fileTable_end:
	mov si, goBackMsg			; show go back msg
	call print_string
	mov ah, 0x00				; get keystroke
	int 0x16
	jmp main_menu				; go back to main menu

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

	mov si, goBackMsg			; show go back message
	call print_string
	mov ah, 0x00				; get key stroke
	int 0x16
	jmp main_menu				; go back to main menu

graphics_test:
	;; Set window and clear it (gfx mode)
	call resetGraphicsScreen

	;; Test square
	mov ah, 0x0C				; write gfx px
	mov al, 0x01				; blue
	mov bh, 0x00				; page number
	
	;; Starting px of square
	mov cx, 100					; colomn number
	mov dx, 100					; row number
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
	jne squareColLoop			; pixels for next row

	mov ah, 0x00				; get key stroke
	int 0x16
	jmp main_menu				; go back to main menu

;; menu N) End program
end_program:
	cli							; clear interrupts
	hlt							; halt the cpu

;; convert hex byte to ascii
print_hex_as_ascii:
	mov ah, 0x0e
	add al, 0x30				; convert to ascii number
	cmp al, 0x39				; is value 0h-9h or A-F
	jle hexNum
	add al, 0x7					; add hex to get ascii 'A' - 'F'

hexNum:
	int 0x10
	ret

;; print out cx number of space to screen
print_blanks_loop:
	cmp cx, 0
	je end_blanks_loop
	mov ah, 0x0e
	mov al, " "
	int 0x10
	dec cx
	jmp print_blanks_loop

end_blanks_loop:
	ret

;; Include other file(s)
include "../print/print_string.asm"
include "../print/print_hex.asm"
include "../print/print_registers.asm"
include "../screen/set_text_screen.asm"
include "../screen/set_graphics_screen.asm"

startMessage:
        db "--------------------------------", 0xA, 0xD,\
	"Kernel Booted, Welcome to TedOS.", 0xA, 0xD,\
	"--------------------------------", 0xA, 0xD, 0xA, 0xD, 0
prompt:
	db ">", 0
	
success:
	db 0xA, 0xD, "Command/Program found !", 0xA, 0xD, 0
failMsg:
	db 0xA, 0xD, "Command or program not found :(", 0xA, 0xD, 0
pgmNotFoundString:
	db 0xA, 0xD, "Program not found, try again ? (Y)", 0xA, 0xD, 0
sectorNotFound:
	db 0xA, 0xD, "Sector not found, try again ? (Y)", 0xA, 0xD, 0
pgmNotLoaded:
	db 0xA, 0xD, "Program not loaded correctly !",\
	0xA, 0xD, "Press any key to go back to file browser ...", 0xA, 0xD, 0
goBackMsg:mov al, 0xA
	db 0xA, 0xD, 0xA, 0xD, "Press any key to go back ...", 0
dbgTest:
	db "Test", 0

fileTableHeading:   db "----------   ---------   -------   ------------   --------------",\
	0xA,0xD,"File Name    Extension   Entry #   Start Sector   Size (sectors)",\
	0xA,0xD,"----------   ---------   -------   ------------   --------------",\
	0xA,0xD,0
printRegHeading:
	db "--------  ------------", 0xA, 0xD,\
	"Register  Mem Location", 0xA, 0xD,\
	"--------  ------------", 0xA, 0xD, 0

cmdDir:
	db "dir",0
cmdReboot:
	db "reboot",0
cmdPrtreg:
	db "prtreg",0
cmdGfx:
	db "gfx",0
cmdHalt:
	db "hlt",0

cmdLength:
	db 0
cmdString:
	db ""

;; Boot Padding magic
times 1536-($-$$) db 0			; pad file with 0s until 1536th bytes

;;;Kernel.asm: Basic kernel loaded from bootsector
;;;

main_menu:
	;; Set window and clear it
	include "../screen/set_window.asm"

	;; print screen heading and menu options
	mov si,	startMessage		; moving memory adress at testString into BX reg
	call print_string

;; Get user input, print to screen & choose menu opt or run prog
get_input:
	mov di, cmdString		; di now pointing to cmdString

keyloop:
	mov ax, 0x00
	int 0x16			; BIOS int get keystroke

	mov ah, 0x0e
	cmp al, 0xD			; did user press 'enter' key?
	je run_command
	int 0x10			; print input char to screen
	mov [di], al			; store input char to string
	inc di				; go to next byte at di
	jmp keyloop			; loop for next char from user

run_command:
	mov byte [di], 0		; null terminate cmdString from di
	mov al, [cmdString]
	cmp al, "F"			; file table command
	je file_browser
	cmp al, "R"			; warm reboot command
	je reboot
	cmp al, "P"			; print reg command
	je print_registers_values
	cmp al, "N"			; end our current program
	je end_program
	mov si, failure			; command not found
	call print_string
	jmp get_input

;; menu F) File Browser
file_browser:
	;; Set window and clear it
	include "../screen/set_window.asm"

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
		cmp al, "}"		; at end of file tab ?
		je stop
		cmp al, "-"		; at sector number of element ?
		je sectorNumber_loop
		cmp al, ","		; between table elements
		je next_element
		inc cx			; increment counter
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
		xor cx, cx		; reset counter
		mov al, 0xA
		int 0x10
		mov al, 0xD
		int 0x10
		mov al, 0xA
                int 0x10
                mov al, 0xD
                int 0x10
		jmp fileTable_loop

	stop:
		mov si, goBackMsg	; show go back message
		call print_string
		mov ah, 0x00		; get key stroke
		int 0x16
		jmp main_menu		; go back to main menu

;; menu R) Reboot
reboot:
	jmp 0xFFFF:0x0000

;; menu P) Print register values
print_registers_values:
	;; Set window and clear it
	include "../screen/set_window.asm"

	mov si, printRegHeading
	call print_string

	call print_registers

	mov si, goBackMsg		; show go back message
        call print_string
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

startMessage:
        db "--------------------------------", 0xA, 0xD,\
	"Kernel Booted, Welcome to TedOS.", 0xA, 0xD,\
	"--------------------------------", 0xA, 0xD, 0xA, 0xD,\
	"F) File Browser", 0xA, 0xD,\
	"R) Reboot", 0xA, 0xD,\
	"P) Print Register Values", 0xA, 0xD, 0
success:
	db 0xA, 0xD, "Command ran successfully", 0xA, 0xD, 0
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
goBackMsg:
	db 0xA, 0xD, 0xA, 0xD, "----------------------------",\
	0xA, 0xD, "Press any key to go back ...", 0
cmdString:
	db ""

;; Boot Padding magic
times 1024-($-$$) db 0			; pad file with 0s until 510th bytes

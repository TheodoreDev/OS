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
	je get_input				; handle empty input
	
	mov byte [si], 0			; null terminate cmdString from di
	mov si, cmdString			; reset di to point to start of user input

check_commands:
	push cx
	mov di, cmdDir				; file table command
	repe cmpsb
	je fileTable
	
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
	push cx
	mov di, cmdClear			; clear the screen by scrolling
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je clear_screen

	pop cx						; restore cx from the stack
	push cx
	mov di, cmdShutd			; shutdown command
	mov si, cmdString			; reset di to point to start of user input
	repe cmpsb
	je shutdown

	pop cx						; restore cx from the stack

check_files:
	mov ax, 0x1000
	mov es, ax					; reset ES:BX to beginning of the file table
	xor bx, bx					; reset ES:BX to point to beginning of file table
	mov si, cmdString			; reset si to start of user input

check_next_char_pgm:
	mov al, [ES:BX]				; get file table char
	cmp al, 0 					; at the end of the file table ?
	je input_not_found			; if yes, pgm not found

	cmp al, [si]				; does user input match file table char ?
	je start_compare_pgm

	add bx, 16					; get next char in file table
	jmp check_next_char_pgm		; check loop

start_compare_pgm:
	push bx						; save file table position

compare_pgm_loop:
	mov al, [ES:BX]				; get file table char
	inc bx						; next byte in input/filetable
	cmp al, [si]				; does input match filetable char
	jne restart_search			; if not, search again from here

	dec cl						; decrement length counter
	jz found_pgm				; counter = 0, program found
	inc si						; go to next byte of input
	jmp compare_pgm_loop

restart_search:
	mov si, cmdString			; reset to start of user input
	pop bx						; restore file table position
	inc bx						; go to next char in file table
	jmp check_next_char_pgm		; start checking again

;; Read disk sector of pgm to memory and execute it by far jmp
found_pgm:
	;; get file extention
	mov al, [ES:BX]
	mov [fileExt], al
	mov al, [ES:BX+1]
	mov [fileExt+1], al
	mov al, [ES:BX+2]
	mov [fileExt+2], al
	
	add bx, 4					; go to starting sector of user input
	mov cl, [ES:BX]				; use to get sector number
	inc bx
	mov bl, [ES:BX]				; file size in sector / number of sector to read
	mov byte [fileSize], bl

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
	jnc run_program				; carry flag not set, succes

	mov si, pgmNotLoaded		; pgm not loaded correctly, error
	call print_string
	jmp get_input				; go back to prompt	

run_program:
	;; Check file extention in file table entry
	mov cx, 3
	mov si, fileExt
	mov ax, 2000h				; Reset es to kernel space for comparison (ES = DS)
	mov es, ax					; ES <- 0x2000
	mov di, fileBin
	repe cmpsb
	jne print_txt				; if txt, print it to screen

	mov ax, 0x8000				; pgm loaded, set segment reg to location
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	jmp 0x8000:0x0000			; far jmp to pgm

print_txt:
	mov ax, 8000h				; Set ES back to file memory location
	mov es, ax					; ES <- 0x8000
	xor cx, cx
	mov ah, 0x0e
	
add_cx_size:
	imul cx, word [fileSize], 512

print_file_char:
	mov al, [ES:BX]
	cmp al, 0Fh
	jle call_hex_to_ascii
	
return_file_char:
	int 10h						; print file char to screen
	inc bx
	loop print_file_char		; keep printing char and decrement CX until 0
	jmp get_input				; go back to prompt

call_hex_to_ascii:
	call hex_to_ascii
	jmp return_file_char

input_not_found:
	mov si, failMsg				; command not found
	call print_string
	jmp get_input

;; Command File Table
fileTable:
	call print_fileTable
	jmp get_input

;; Command Reboot
reboot:
	jmp 0xFFFF:0x0000

;; Command Print register values
print_registers_values:
	mov si, printRegHeading
	call print_string

	call print_registers
	jmp get_input

;; Command graphics mode test
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

;; Command clear screen
clear_screen:
	call resetTextScreen
	jmp get_input

;; Command shutdown
shutdown:
	;; outw(0x604, 0x2000)
	mov ax, 2000h
	mov dx, 604h
	out dx, ax

;; menu N) End program
end_program:
	cli							; clear interrupts
	hlt							; halt the cpu

;; convert hex byte to ascii
hex_to_ascii:
	mov ah, 0x0e
	add al, 0x30				; convert to ascii number
	cmp al, 0x39				; is value 0h-9h or A-F
	jle hexNum
	add al, 0x7					; add hex to get ascii 'A' - 'F'

hexNum:
	ret

;; print out cx number of space to screen
print_blanks_loop:
	mov ah, 0x0e
	mov al, " "
	int 0x10
	loop print_blanks_loop
	ret

;; Include other file(s)
include "../print/print_string.asm"
include "../print/print_hex.asm"
include "../print/print_registers.asm"
include "../print/print_fileTable.asm"
;;include "../screen/clear_screen.asm"
include "../screen/set_text_screen.asm"
include "../screen/set_graphics_screen.asm"

nl equ 0xA, 0xD

startMessage:
        db "--------------------------------", nl,\
	"Kernel Booted, Welcome to TedOS.", nl,\
	"--------------------------------", nl, 0
prompt:
	db nl, "OS/>", 0
	
success:
	db nl, "Command/Program found !", nl, 0
failMsg:
	db nl, "Command/Program not found :(", nl, 0
pgmNotFoundString:
	db nl, "Program/file not found, try again ? (Y)", nl, 0
sectorNotFound:
	db nl, "Sector not found, try again ? (Y)", nl, 0
pgmNotLoaded:
	db nl, "Program found but not loaded correctly !", nl, 0
goBackMsg:
	db nl, nl, "Press any key to go back ...", 0
dbgTest:
	db "Test", 0

fileTableHeading:
	db nl, "----------   ---------   -------   ------------   --------------",\
	nl,"File Name    Extension   Entry #   Start Sector   Size (sectors)",\
	nl,"----------   ---------   -------   ------------   --------------",\
	nl,0
printRegHeading:
	db nl, "--------  ------------", nl,\
	"Register  Mem Location", nl,\
	"--------  ------------", nl, 0

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
cmdClear:
	db "cls", 0
cmdShutd:
	db "shutdown", 0
cmdEdt:
	db "editor", 0

cmdLength:
	db 0
fileExt:
	db "   ", 0
fileSize:
	db 0
fileBin:
	db "bin", 0
fileTxt:
	db "txt", 0
cmdString:
	db ""

;; Boot Padding magic
times 2048-($-$$) db 0			; pad file with 0s until 1536th bytes

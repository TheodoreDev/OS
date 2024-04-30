;;;
;;;

call clear_screen_text_mode

mov si, testMsg
call print_string

mov ah, 0x00
int 0x16

mov ax, 0x200
mov es, ax
xor bx, bx					; ES:BX -> 0x2000:0x0000

mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
jmp 200h:0000h				; far jmp back to kernel

include "../include/print/print_string.inc"
include "../include/screen/clear_screen_text_mode.inc"

testMsg:
	db "Program Loaded !", 0

times 512-($-$$) db 0		; pad out to 1 sector

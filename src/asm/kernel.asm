;;;Kernel.asm: Basic kernel loaded from bootsector
;;;

;; Set video mode
mov ah, 0x00                            ; int 0x10/ AH 0x00 = set video mode
mov al, 0x03                            ; 80x25 text mode
int 0x10

;; Change color/Palette
mov ah, 0x0B
mov bh, 0x00
mov bl, 0x01
int 0x10

mov si, testString                      ; moving memory adress at testString into BX reg
call print_string

;; Include other file(s)
include "../print/print_string.asm"

hlt                                   	; halt the cpu

testString:
        db "Kernel Booted, Welcome to TedOS.", 0xA, 0xD, 0

;; Boot Padding magic
times 510-($-$$) db 0                   ; pad file with 0s until 510th bytes

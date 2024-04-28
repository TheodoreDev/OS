;;; Basic boot loader uses INT13 AH2
;;;

org 0x7c00								; 'origin' of Boot code; help make sure adress don't change

;; read file table into memory second
;; set up ES:BX memory adress to load sector(s) into
mov bx, 0x1000							; load sector to memory adress 0x1000
mov es, bx								; ES = 0x1000
mov bx, 0x0								; ES:BX = 0x1000:0

;; set up disk read
mov dh, 0x0								; head 0
mov dl, 0x0								; drive 0
mov ch, 0x0								; cylinder 0
mov cl, 0x06							; starting sector to read from disk

load_file:
	mov ah, 0x02						; BIOS int 13/ah=2 read disk sector
	mov al, 0x01						; number of sector to read
	int 0x13							; BIOS interrupts for disk functions

	jc load_file						; retry if disk read error (carry = 1)

;; read kernel into memory first
;; set up ES:BX memory adress to load sector(s) into
mov bx, 0x2000                          ; load sector to memory adress 0x2000
mov es, bx                              ; ES = 0x2000
mov bx, 0x0                             ; ES:BX = 0x2000:0

;; set up disk read
mov dh, 0x0                             ; head 0
mov dl, 0x0                             ; drive 0
mov ch, 0x0                             ; cylinder 0
mov cl, 0x02                            ; starting sector to read from disk

load_kernel:
	mov ah, 0x02						; BIOS int 13/ah=2 read disk sector
	mov al, 0x04						; number of sector to read
	int 0x13							; BIOS interrupts for disk functions

	jc load_kernel						; retry if disk read error (carry = 1)

;; reset segment reg for RAM
mov ax, 0x2000
mov ds, ax								; data segment
mov es, ax								; extra segment
mov fs, ax								; " "
mov gs, ax								; " "

;; Set up stack segment
mov sp, 0FFFFh							; stack pointer
mov ax, 9000h
mov ss, ax								; stack segment

jmp 0x2000:0x0							; never return from this

;; Boot Sector magic
times 510-($-$$) db 0                   ; pad file with 0s until 510th bytes  
dw 0xaa55								; BIOS magic number in 511th and 512th bytes

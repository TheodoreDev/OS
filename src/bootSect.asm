;;; Basic boot loader uses INT13 AH2
;;;

org 0x7c00								; 'origin' of Boot code; help make sure adress don't change

;; read file table into memory second
;; set up ES:BX memory adress to load sector(s) into
mov bx, 0x100							; load sector to memory adress 0x1000
mov es, bx								; ES = 0x1000
xor bx, bx								; ES:BX = 0x100:0

;; set up disk read
xor dx, dx								; dh = head number, dl = drive number
mov cx, 0006h							; ch = cylinder number, cl = starting sector

load_file:
	mov ax, 0201h						; int 13/ah=2 read disk sector, al = # of sector to read
	int 0x13							; BIOS interrupts for disk functions

	jc load_file						; retry if disk read error (carry = 1)

;; read kernel into memory first
;; set up ES:BX memory adress to load sector(s) into
mov bx, 0x200							; load sector to memory adress 0x2000
mov es, bx								; ES = 0x2000
xor bx, bx	 							; ES:BX = 0x200:0

;; set up disk read
xor dx, dx								; dh = head number, dl = drive number
mov cx, 0002h							; ch = cylinder number, cl = starting sector

load_kernel:
	mov ax, 0204h						; int 13/ah=2 read disk sector, al = # of sector to read
	int 0x13							; BIOS interrupts for disk functions

	jc load_kernel						; retry if disk read error (carry = 1)

;; reset segment reg for RAM
mov ax, 0x200
mov ds, ax								; data segment
mov es, ax								; extra segment
mov fs, ax								; " "
mov gs, ax								; " "

;; Set up stack segment
mov sp, 0FFFFh							; stack pointer
mov ax, 900h
mov ss, ax								; stack segment

;; Set up video mode before going to kernel
mov ax, 0003h
int 0x10

mov ah, 0Bh
mov bx, 0001h
int 0x10
jmp 2000h								; never return from this

;; Boot Sector magic
times 510-($-$$) db 0                   ; pad file with 0s until 510th bytes  
dw 0xaa55								; BIOS magic number in 511th and 512th bytes

;;; clear_screen.asm: clears screen by writing to video memory
;;; assuming VGA txt mode 03 => 80x25 char, 16 colors
;;;

clear_screen_text_mode:
	pusha
	mov ax, 0B800h			; set up video memory
	mov es, ax
	xor di, di				; es:di <- B800:0000
	
	mov ah, 17h				; blue background, light gray foreground
	mov al, ' '				; space
	mov cx, 80*25			; number of char to write

	rep stosw

	;; Move hardware cursor after
	mov ah, 02h				; int 0x10 ah 0x2 = move hardware cursor
	xor bh, bh				; bh = page number
	xor dx, dx				; dh = row to move to, dl = col
	int 0x10
	popa
	ret

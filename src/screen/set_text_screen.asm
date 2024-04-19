;;; set text mode screen (or reset it)
;;;

resetTextScreen:
	;; Set video mode
	mov ah, 0x00                            ; int 0x10/ AH 0x00 = set video mode
	mov al, 0x03                            ; 80x25 text mode
	int 0x10

	;; Change color/Palette
	mov ah, 0x0B
	mov bh, 0x00
	mov bl, 0x01
	int 0x10

	ret

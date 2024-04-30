;;; set graphics mode screen (or reset it)
;;;

resetGraphicsScreen:
	;; Set video mode
	mov ah, 0x00				; int 0x10/ AH 0x00 = set video mode
	mov al, 0x13				; 300x200 graphics mode
	int 0x10

	;; Change color/Palette

	ret

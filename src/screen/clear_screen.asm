;;; clear_screen.asm: clears screen by srolling (BIOS int 0x10 ah 06h)
;;;

clear_screen:
	pusha
	mov ah, 06h
	mov al, 00h
	
	xor cx, cx				; ch/cl = row/col of upper left corner
	mov dh, 24				; dh = row of lower right corner
	mov dl, 79				; dl = col of lower right corner

	int 10h

	popa
	ret

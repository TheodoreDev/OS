;;; move_cursor.inc: move hardware cursor to new row/col
;;; Params:
;;;  input 1: row/col as 2 bytes in a word
;;;

move_cursor:
	push bp
	mov bp, sp
	sub sp, 2				; Local stack variable - error code

	push dx					; save modified register

	;; Get params off stack
	mov dx, [bp+4]			; DX = row/col to move cursor to
	mov ax, [bp+6]			; row value
	mov dh, al

	mov ah, 02h				; int 10h / ah 02h = move cursor
	mov bh, 00h
	int 10h

	mov word [bp-2], 0		; return code = success
	mov ax, [bp-2]
	
	pop dx
	mov sp, bp
	pop bp

	ret
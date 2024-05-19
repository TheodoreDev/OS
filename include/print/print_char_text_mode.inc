;;; print_char_text_mode.inc : Print a single char to video mem
;;; Params:
;;;  input 1 : char to print
;;;  input 2 : row to print to
;;;  input 2 : col to print to
;;;  output 1 : return code in AX

;; CONSTANTS
VIDMEM equ 0B800h
ATTRIBUTE equ 17h

print_char_text_mode:
	push bp
	mov bp, sp
	sub sp, 2					; Local stack variable - error code

	push dx
	push es
	push di

	mov ax, VIDMEM				; set up ES:DI to print to
	mov es, ax

	imul di, [bp+6], 160		; row to print to, in bytes
	imul ax, [bp+4],2			; col to print to, in bytes
	add di, ax					; DI = row*sizeof(col) + col*sizeof(col)

	mov ax, [bp+8]				; char to print
	mov ah, ATTRIBUTE			; char attribute byte (color)
	stosw

	mov word [bp-2], 0				; Success
	mov ax, [bp-2]

	pop di
	pop es
	pop dx

	mov sp, bp
	pop bp

	ret
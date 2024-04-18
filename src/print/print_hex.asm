;;; Prints hexadecimal values using reg DX and print_string.asm
;;;
;;; Ascii '0'-'9' = hex 0x30-0x39
;;; Ascii 'A'-'F' = hex 0x41-0x46
;;; Ascii 'a'-'f' = hex 0x61-0x66
;;;

print_hex:
	pusha			; save all reg to the stack
	xor cx, cx		; init loop counter

hex_loop:
	cmp cx, 4		; are we at the end of loop ?
	je end_hexloop

	;; Convert DX hex value to Ascii
	mov ax, dx
	and ax, 0x000F		; turn 1st 3hex to 0, keep final digit to convert
	add al, 0x30            ; get ascii number of Letter value
	cmp al, 0x39		; is hex value 0-9 (<= 0x39)  ? or A-F (> 0x39) ?
	jle move_intoBX
	add al, 0x7		; to get ascii 'A'-'F'

move_intoBX:
	mov bx, hexString + 5	; base adress of hexString + lenght of string
	sub bx, cx		; subtract loop counter
	mov [bx], al
	ror dx, 4		; rotate right by 4 bits

	add cx, 1               ; increment counter
	jmp hex_loop		; loop for next hex digit in DX

end_hexloop:
	mov si, hexString
	call print_string

	popa			; restore all reg from the stack
	ret			; return to caller

hexString:
	db "0x0000", 0

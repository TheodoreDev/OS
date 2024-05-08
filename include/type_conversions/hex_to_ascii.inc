;;; hex_to_ascii: Convert hex char to ascii equivalent
;;;

hex_to_ascii:
	mov ah, 0x0e
	add al, 0x30				; convert to ascii number
	cmp al, 0x39				; is value 0h-9h or A-F
	jle hexNum
	add al, 0x7					; add hex to get ascii 'A' - 'F'

hexNum:
	ret
;;; Disk load: Read DH sector into ES:BX memory location from drive DL
;;;

disk_load:
	push dx				; store DX on stack
	
retry:
	mov ah, 0x02			; int 13/ah=02h, BIOS read disk sector into memory
	mov al, dh			; number of sectors we want to read
	mov ch, 0x00			; cylinder 0
	mov dh, 0x00			; head 0
	mov cl, 0x02			; start reading at CL sector

	int 0x13			; BIOS interrupts for disk functions
	jc retry			; jump if disk read error (carry = 1)
	pop dx				; restor dx from the stack

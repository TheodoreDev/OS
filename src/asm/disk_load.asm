;;; Disk load: Read DH sector into ES:BX memory location from drive DL
;;;

disk_load:
	push dx				; store DX on stack
	
	mov ah, 0x02			; int 13/ah=02h, BIOS read disk sector into memory
	mov al, dh			; number of sectors we want to read
	mov ch, 0x00			; cylinder 0
	mov dh, 0x00			; head 0
	mov cl, 0x02			; start reading at CL sector (2)

	int 0x03			; BIOS interrupts for disk functions

	jc disk_error			; jump if disk read error (carry = 1)
	
	pop dx				; restore DX from the stack
	cmp dh, al			; if AL(# sector actually read) != DH(sector wanted)
	jne disk_error			; error
	ret				; return to caller

disk_error:
	mov bx, DISK_ERROR_MSG
	call print_string
	hlt

DISK_ERROR_MSG:
	db "[ERROR] Disk read error !", 0

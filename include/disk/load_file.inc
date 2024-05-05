;;; load_file: Read DH sector into ES:BX memory location from drive DL
;;;
;;; Params: Filename, memory location to load file data to
;;;

load_file:
	;; Function prologue
	push bp
	mov bp, sp
	pusha

	;; get params
	mov bx, [bp+4]
	mov fs, [bp+6]			; FS:BX <- memory location to load data to
	mov si, [bp+8]			; filename
	
	;; Copy filename to variable
	mov cx, 10
	mov di, set_file_name_load
	rep movsb

	;; Reset file_name adress
	mov si, set_file_name_load

	;; Search filetable for filename
	xor ax, ax
	mov es, ax
	mov di, 1000h			; location of fileTable in memory
	mov cx, 10

check_filename_load:
	mov al, [ES:DI]
	cmp al, 0 				; end of filetable ?
	je return_to_caller_load

	cmp al, [si]
	je compare_filenames_load

	add di, 16				; go to next file entry in file table
	jmp check_filename_load

compare_filenames_load:
	push di
	
	.loop:
	mov al, [ES:DI]
	inc di
	cmp al, [si]
	jne restart_check_load
	
	dec cl
	jz found_file_load
	inc si
	jmp .loop

restart_check_load:
	mov si, set_file_name_load
	pop di
	inc di
	jmp check_filename_load

found_file_load:
	;; Reset disk
	xor ax, ax				; int 13h ah 00h - reset disk
	xor dl, dl				; Disk 0
	int 13h
	
	;; Set up params for int 13h ah02h - read disk sectors
	add di, 4
	xor ch, ch 				; Track number
	mov cl, [ES:DI]			; sector number to start reading at
	inc di
	mov ax, fs
	mov es, ax				; segment adress to load to, BX already set
	mov ah, 02h				; int 13h ah 02h
	mov al, [ES:DI]			; number of sectors to read
	xor dx, dx				; dh = head number, dl = drive number
	
	int 13h
	jnc return_to_caller_load

	;; Error

return_to_caller_load:
	;; Function epilogue
	popa					; restore registers in initial setup
	mov sp, bp				; Reset stack pointer
	pop bp					; Reset caller's base pointer
	ret

;; Variables
set_file_name_load:	times 10 db 0

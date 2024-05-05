;;; save_file.inc: Save file data to disk
;;;
;;; Params : File name, file ext, file size (in hex sector), memory location to save data from
;;;

save_file:
	;; Function prologue
	push bp
	mov bp, sp
	sub sp, 2				; Make room for local variable - error code
	push bx
	push fs
	push cx
	push dx
	push si

	;; Get params off stack
	mov bx, [bp+4]
	mov fs, [bp+6]			; FS:BX memory location to save data from
	mov cx, [bp+8]			; file size
	mov dx, [bp+10]			; file ext
	mov si, [bp+12] 		; file name

	;; Copy file size to variable
	mov byte [file_size], cl

	;; Copy filename to variable
	mov cx, 10
	mov di, set_file_name_save
	rep movsb

	;; Copy file ext to variable
	mov di, file_type
	mov si, dx
	mov cx, 3
	rep movsb

	;; Reset file_name adress
	mov si, set_file_name_save
	
	;; Search filetable for filename
	xor ax, ax
	mov es, ax
	mov di, 1000h			; location of fileTable in memory
	mov cx, 10

check_filename_save:
	;; Get starting sector of file + file size in sectors
	mov al, byte [ES:DI+14]	; Starting sector
	cmp al, 0
	je new_file				; No starting sector, file doesn't exist, create new file

	add al, [ES:DI+15]		; file size in sectors
	mov byte [last_saved_sector], al
	
	mov al, [ES:DI]
	cmp al, [si]			; end of filetable ?
	je compare_filenames_save

	add di, 16				; go to next file entry in file table
	jmp check_filename_save

compare_filenames_save:
	mov di, set_file_name_save
	push di
	
	.loop:
	mov al, [ES:DI]
	inc di
	cmp al, [si]
	jne restart_check_save
	
	dec cl
	jz found_file_save
	inc si
	jmp .loop

restart_check_save:
	mov si, set_file_name_save
	pop di
	add di, 16				; go to next file table entry
	jmp check_filename_save

found_file_save:
	;; Reset disk
	xor ax, ax				; int 13h ah 00h - reset disk
	xor dl, dl				; Disk 0
	int 13h

	;; File exist in file table and on disk

new_file:
	;; Create new file table entry at end of current entry
	mov cx, 10
	mov si, set_file_name_save
	rep movsb				; Move 10 bytes of filename in si to filetable in di
	mov cx, 3
	mov si, file_type
	rep movsb				; Move 3 bytes of file extention in si to filetable
	xor al, al 
	stosb					; Directory entry number (0 = first entry)
	mov al, byte [last_saved_sector]
	stosb					; starting sector
	mov al, byte [file_size]
	stosb					; File size

	;; Write change filetable to disk
	xor ch, ch					; track number
	mov cl, 06h					; sector number to start writting at
	xor dx, dx					; dh = head number, dl = drive number
	mov word [saved_bx], bx
	xor ax, ax
	mov es, ax
	mov bx, 1000h				; ES:BX <- 0000h:1000h (file table mem location)
	mov ah, 03h					; int 13h ah 03h - write disk sector
	mov al, 01h					; number of sector to write

	int 13h
	jnc write_file_data

write_file_data:
	mov ax, fs 
	mov es, ax

	mov ah, 03h					; int 13h ah 03h - write disk sector
	mov al, byte [file_size]	; number of sector to write
	xor ch, ch					; track number
	mov cl, byte [last_saved_sector]
	xor dx, dx					; dh = head number, dl = drive number
	mov bx, word [saved_bx]		; ES:BX <- file data memory location

	int 13h
	jnc return_to_caller_save

	;; Disk write error
	mov word [bp-2], 1			; error happend

return_to_caller_save:
	;; Function epilogue, restore registers in initial setup
	mov ax, [bp-2]			; error code
	pop si
	pop dx
	pop cx
	pop fs
	pop bx
	mov sp, bp				; Reset stack pointer
	pop bp					; Reset caller's base pointer
	ret

;; Variables
set_file_name_save:	times 10 db 0
file_type:	times 3 db 0
file_size:	db 0
last_saved_sector:	db 0
saved_bx:	dw 0
error_code:	dw 0

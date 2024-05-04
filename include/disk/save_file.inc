;;; save_file.inc: Save file data to disk
;;;
;;; Params : File name, file ext, file size (in hex sector), memory location to save data from, error code
;;;

save_file:
	;; Get params off stack
	pop ax					; error code
	mov word [error_code], ax
	pop bx
	pop fs					; FS:BX memory location to save data from
	pop cx					; file size
	pop ax					; file ext
	pop si 					; file name

	;; Copy file size to variable
	mov byte [file_size], cl

	;; Copy file ext to variable
	mov cx, 3
	mov di, set_file_ext
	rep stosb

	;; Copy filename to variable
	mov cx, 10
	mov di, set_file_name_save
	.loop:
	lodsb
	stosb
	loop .loop

	;; Reset file_name adress
	mov si, set_file_name_save
	
	;; Search filetable for filename
	xor ax, ax
	mov es, ax
	mov di, 1000h			; location of fileTable in memory
	mov cx, 10

check_filename_save:
	;; Get starting sector of file + file size in sectors
	mov al, [ES:DI+14]		; starting sector
	mov byte [last_saved_sector], al
	mov al, [ES:DI+15]		; file size in sectors
	add byte [last_saved_sector], al
	
	mov al, [ES:DI]
	cmp al, 0 				; end of filetable ?
	je new_file

	cmp al, [si]
	je compare_filenames_save

	add di, 16				; go to next file entry in file table
	jmp check_filename_save

compare_filenames_save:
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
	mov si, set_file_ext
	rep movsb				; Move 3 bytes of file extention in si to filetable
	xor al, al 
	stosb					; Directory entry number (0 = first entry)
	mov al, byte [last_saved_sector]
	stosb					; starting sector
	mov al, byte [file_size]
	stosb					; File size

	;; Write change filetable to disk
	mov ah, 03h					; int 13h ah 03h - write disk sector
	mov al, 01h					; number of sector to write
	xor ch, ch					; track number
	mov cl, 06h					; sector number to start writting at
	xor dx, dx					; dh = head number, dl = drive number
	mov word [saved_bx], bx
	mov bx, 1000h				; ES:BX <- 0000h:1000h (file table mem location)

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
	mov word [error_code], 1	; error happend
	push word [error_code]

return_to_caller_save:
	ret


;; Variables
set_file_name_save:	times 10 db 0
set_file_ext:	times 3 db 0
file_size:	db 0
last_saved_sector:	db 0
saved_bx:	dw 0
error_code:	dw 0

;;; save_file.inc: Save file data to disk
;;;
;;; Params : File name, file size (in hex sector), memory location to save data from
;;;

save_file:
	;; Get params off stack
	pop bx
	pop fs					; FS:BX memory location to save data from
	pop cx					; file size
	pop si 					; file name

	;; Copy filename to variable
	mov cx, 10
	mov di, file_name
	.loop:
	lodsb
	stosb
	loop .loop

	;; Reset file_name adress
	mov si, file_name


;; Variables
file_name:	times 10 db 0

;;; fileTable.asm: basic file table made with db
;;; string consists of '{fileName1-sector#, fileName2-sector#, ... , fileNameN-sector#}'
;;;

db "{calculator-04,test-06}"

;; sector padding magic
times 512-($-$$) db 0 				; pad rest of file to 0s till end of sector

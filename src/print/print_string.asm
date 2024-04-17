;;; Print string
;;;

print_string:
        mov ah, 0x0e                    ; int 10/ah 0x0e BIOS teletype output
        mov bh, 0x0                     ; page number
        mov bl, 0x07                    ; color

print_char:
        mov al, [si]                    ; move character value at adress in bx into al
        cmp al, 0
        je end_print                    ; jump if equal (al = 0) to halt label
        int 0x10                        ; print char in al
        add si, 1                       ; move 1 byte forward
        jmp print_char                  ; loop

end_print:
        ret

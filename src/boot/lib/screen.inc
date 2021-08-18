;authors: initkfs
bits 32
;
; Print message
;
printMessage:
   push edx
   push eax

   mov edx, 0xb8000 ; set video memory address

;TODO update cursor position
.printCharLoop:
    mov al, [ebx]   ; set character
    mov ah, 0x0F    ; white on black attribute

    test al, al
    je .exit

    mov [edx], ax   ; write character + attribute in video memory
    
    inc ebx         ; next char
    add edx, 2      ; next video memory position

    jmp .printCharLoop

.exit:
   pop eax
   pop edx
   ret

;
; Disable cursor
;
cursorDisable:
.saveEflags:
	pushf
.saveRegisters:
	push eax
	push edx
 
 .disableCursor:
	mov dx, 0x3D4
	mov al, 0xA
	out dx, al
 
	inc dx
	mov al, 0x20
	out dx, al

.restoreRegisters: 
	pop edx
	pop eax
.restoreEflags:
	popf

.exit:
	ret
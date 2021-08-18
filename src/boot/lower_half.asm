;authors: initkfs

global lowerHalfStart

extern kmain		; kernel.d

section .text
bits 64
lowerHalfStart:
	mov rax, QWORD kmain ;call kernel
	call rax
.hang:
	hlt
	jmp .hang

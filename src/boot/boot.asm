;authors: initkfs

%include "lib/screen.inc"
%include "lib/util.inc"

extern lowerHalfStart

;Multiboot2 specification: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#kernel_002ec
section .multibootHeader
headerStart:
    dd 0xE85250D6                ; magic
    dd 0                         ; architecture, protected mode x32
    dd headerEnd - headerStart ; header length
    dd 0x100000000 - (0xe85250d6 + 0 + (headerEnd - headerStart)) ;checksum
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
headerEnd:

section .data
STACKSIZE equ 0x10000 ; 64kb
bootStartMessage: db "Start bootloader", 0

section .text
bootstrap:

global start
extern kmain

bits 32 
start:

mov edi, eax 		; multiboot2 argument - magic constant
mov esi, ebx 		; multiboot2 argument - multiboot header struct address

mov ebx, bootStartMessage
call cursorDisable
call printMessage

mov esp, stackPointer

call enablePaging

lgdt [gdt64.pointer]

mov ax, gdt64.data
mov ss, ax
mov ds, ax
mov es, ax

jmp gdt64.code:lowerHalfStart

enablePaging:
	;set page level 4
	mov eax, p4Table
	mov cr3, eax

	; enable PAE, set CR4.PAE, bit 5 = 1
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set long mode bit (8) and NXE (11) in EFER register
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	or eax, 1 << 11
	wrmsr

	; enable paging
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax
.exit:
	ret

; section .rodata
gdt64:
	dq 0;												
.code: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)	; code segment, 64-bit, present, read/write, executable
.data: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41)						; data segment, present, read/write
.pointer:
	dw $ - gdt64 - 1
	dq gdt64

stack:
	times STACKSIZE db 0
stackPointer:

; TODO recursive paging
; https://wiki.osdev.org/D_Bare_Bones
; https://wiki.osdev.org/D_barebone_with_ldc2
align 4096
p4Table:					
	dq (p3Table + 0x3)		;present | writable
	times 255 dq 0			 
	dq (p3Table + 0x3)		;present | writable
	times 254 dq 0
	dq (p4Table + 0x3)		; recursive entry.
align 4096
p3Table:
	dq (p2Table + 0x3)
	times 511 dq 0
align 4096
p2Table:
	%assign i 0
	%rep 50 ; TODO remapping from code. 50 tables yet.
	dq (p1Table + i + 0x3)
	%assign i i+4096
	%endrep
	times (512-50) dq 0
align 4096
p1Table:
	%assign i 0				
	%rep 512*50
	dq (i << 12) | 0x03
	%assign i i+1
	%endrep

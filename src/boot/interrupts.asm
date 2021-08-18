bits 64

;from D code
extern runInterruptServiceRoutine
extern runInterruptRequest

;https://wiki.osdev.org/Interrupts
global isr0
global isr1
global isr2
global isr3
global isr4
global isr5
global isr6
global isr7
global isr8
global isr9
global isr10
global isr11
global isr12
global isr13
global isr14
global isr15
global isr16
global isr17
global isr18
global isr19
global isr20
global isr21
global isr22
global isr23
global isr24
global isr25
global isr26
global isr27
global isr28
global isr29
global isr30
global isr31

global isr128				; 0x80 syscall

global irq0
global irq1
global irq2
global irq3
global irq4
global irq5
global irq6
global irq7
global irq8
global irq9
global irq10
global irq11
global irq12
global irq13
global irq14
global irq15

;isr\irq label
;cli - clear interrupt
;error code
;number of interrupt\exception
;jump to handler

; divide by 0
isr0:
	cli
	push long 0
	push long 0
	jmp isrHandler

; debug exception
isr1:
	cli
	push long 0
	push long 1
	jmp isrHandler

; NMI
isr2:
	cli
	push long 0
	push long 2
	jmp isrHandler

; breakpoint
isr3:
	cli
	push long 0
	push long 3
	jmp isrHandler

; into detected overflow
isr4:
	cli
	push long 0
	push long 4
	jmp isrHandler

; out of bounds
isr5:
	cli
	push long 0
	push long 5
	jmp isrHandler

; invalid opcode
isr6:
	cli
	push long 0
	push long 6
	jmp isrHandler

; no co-processor
isr7:
	cli
	push long 0
	push long 7
	jmp isrHandler

; double fault
isr8:
	cli
	; returns error code
	push long 3
	jmp isrHandler

; coprocessor segment overrun
isr9:
	cli
	push long 0
	push long 9
	jmp isrHandler

; bad TSS exception
isr10:
	cli
	; returns error code
	push long 10
	jmp isrHandler

; segment not present
isr11:
	cli
	; returns error code
	push long 11
	jmp isrHandler

; stack fault
isr12:
	cli
	; returns error code
	push long 12
	jmp isrHandler

; GPF exception
isr13:
	cli
	; returns error code
	push long 13
	jmp isrHandler

; page fault
isr14:
	cli
	; returns error code
	push long 14
	jmp isrHandler

; unknown interrupt
isr15:
	cli
	push long 0
	push long 15
	jmp isrHandler

; coprocessor fault
isr16:
	cli
	push long 0
	push long 16
	jmp isrHandler

; alignment check exception
isr17:
	cli
	push long 0
	push long 17
	jmp isrHandler

; machine check exception
isr18:
	cli
	push long 0
	push long 18
	jmp isrHandler

; Interrupts 19-31: reserved
isr19:
	cli
	push long 0
	push long 19
	jmp isrHandler

isr20:
	cli
	push long 0
	push long 20
	jmp isrHandler

isr21:
	cli
	push long 0
	push long 21
	jmp isrHandler

isr22:
	cli
	push long 0
	push long 22
	jmp isrHandler

isr23:
	cli
	push long 0
	push long 23
	jmp isrHandler

isr24:
	cli
	push long 0
	push long 24
	jmp isrHandler

isr25:
	cli
	push long 0
	push long 25
	jmp isrHandler

isr26:
	cli
	push long 0
	push long 26
	jmp isrHandler

isr27:
	cli
	push long 0
	push long 27
	jmp isrHandler

isr28:
	cli
	push long 0
	push long 28
	jmp isrHandler

isr29:
	cli
	push long 0
	push long 29
	jmp isrHandler

isr30:
	cli
	push long 0
	push long 30
	jmp isrHandler

isr31:
	cli
	push long 0
	push long 31
	jmp isrHandler

irq0:
	cli
	push long 0
	push long 32
	jmp irqHandler

irq1:
	cli
	push long 0
	push long 33
	jmp irqHandler

irq2:
	cli
	push long 0
	push long 34
	jmp irqHandler

irq3:
	cli
	push long 0
	push long 35
	jmp irqHandler

irq4:
	cli
	push long 0
	push long 36
	jmp irqHandler

irq5:
	cli
	push long 0
	push long 37
	jmp irqHandler

irq6:
	cli
	push long 0
	push long 38
	jmp irqHandler

irq7:
	cli
	push long 0
	push long 39
	jmp irqHandler

irq8:
	cli
	push long 0
	push long 40
	jmp irqHandler

irq9:
	cli
	push long 0
	push long 41
	jmp irqHandler

irq10:
	cli
	push long 0
	push long 42
	jmp irqHandler

irq11:
	cli
	push long 0
	push long 43
	jmp irqHandler

irq12:
	cli
	push long 0
	push long 44
	jmp irqHandler

irq13:
	cli
	push long 0
	push long 45
	jmp irqHandler

irq14:
	cli
	push long 0
	push long 46
	jmp irqHandler

irq15:
	cli
	push long 0
	push long 47
	jmp irqHandler

isr128:
	cli
	push long 0
	push long 0x80
	jmp isrHandler

isrHandler:
	pop rdi 				; first argument to isr(), interrupt number
	pop rsi 				; second argument to isr(), error code (if CPU sets one)
	
	push rdi
	push rsi
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11
	; compiler preserves rbx, rbp, r12-r15
	push rax
	
	mov rax, QWORD runInterruptServiceRoutine
	call rax
	
	pop rax
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rsi
	pop rdi

	iretq

irqHandler:
	pop rdi
	pop rsi

	push rdi
	push rsi
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11
	; compiler preserves rbx, rbp, r12-r15
	push rax
	
	mov rax, QWORD runInterruptRequest
	call rax
	
	pop rax
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rsi
	pop rdi

	iretq	
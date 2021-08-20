/**
 * Authors: initkfs
 */
module os.core.interrupt.isr;

private
{
	alias Irq = os.core.interrupt.irq;
}

/*
* https://wiki.osdev.org/Exceptions
*/
enum Exception
{
	DivideByZero,
	Debug,
	Nmi,
	Breakpoint,
	Overflow,
	BoundRangeExceed,
	InvalidOpcode,
	DeviceNotAvailable,
	DoubleFault,
	SegmentOverrun, //legacy
	InvalidTss,
	SegmentNotPresent,
	StackSegmentFault,
	GeneralProtectionFault,
	PageFault,
	Reserved,
	FloatingPointException,
	AlignmentCheck,
	MachineCheck,
	SimdFpException,
	VirtualizationException
}

extern (C) __gshared void isr0();
extern (C) __gshared void isr1();
extern (C) __gshared void isr2();
extern (C) __gshared void isr3();
extern (C) __gshared void isr4();
extern (C) __gshared void isr5();
extern (C) __gshared void isr6();
extern (C) __gshared void isr7();
extern (C) __gshared void isr8();
extern (C) __gshared void isr9();
extern (C) __gshared void isr10();
extern (C) __gshared void isr11();
extern (C) __gshared void isr12();
extern (C) __gshared void isr13();
extern (C) __gshared void isr14();
extern (C) __gshared void isr15();
extern (C) __gshared void isr16();
extern (C) __gshared void isr17();
extern (C) __gshared void isr18();
extern (C) __gshared void isr19();
extern (C) __gshared void isr20();
extern (C) __gshared void isr21();
extern (C) __gshared void isr22();
extern (C) __gshared void isr23();
extern (C) __gshared void isr24();
extern (C) __gshared void isr25();
extern (C) __gshared void isr26();
extern (C) __gshared void isr27();
extern (C) __gshared void isr28();
extern (C) __gshared void isr29();
extern (C) __gshared void isr30();
extern (C) __gshared void isr31();

extern (C) __gshared void isr128();

void setDefaultIsr(const ubyte num, void* isr)
{
	Irq.addDefaultIrqGate(num, isr);
}

void init()
{
	setDefaultIsr(0, &isr0);
	setDefaultIsr(1, &isr1);
	setDefaultIsr(2, &isr2);
	setDefaultIsr(3, &isr3);
	setDefaultIsr(4, &isr4);
	setDefaultIsr(5, &isr5);
	setDefaultIsr(6, &isr6);
	setDefaultIsr(7, &isr7);
	setDefaultIsr(8, &isr8);
	setDefaultIsr(9, &isr9);
	setDefaultIsr(10, &isr10);
	setDefaultIsr(11, &isr11);
	setDefaultIsr(12, &isr12);
	setDefaultIsr(13, &isr13);
	setDefaultIsr(14, &isr14);
	setDefaultIsr(15, &isr15);
	setDefaultIsr(16, &isr16);
	setDefaultIsr(17, &isr17);
	setDefaultIsr(18, &isr18);
	setDefaultIsr(19, &isr19);
	setDefaultIsr(20, &isr20);
	setDefaultIsr(21, &isr21);
	setDefaultIsr(22, &isr22);
	setDefaultIsr(23, &isr23);
	setDefaultIsr(24, &isr24);
	setDefaultIsr(25, &isr25);
	setDefaultIsr(26, &isr26);
	setDefaultIsr(27, &isr27);
	setDefaultIsr(28, &isr28);
	setDefaultIsr(29, &isr29);
	setDefaultIsr(30, &isr30);
	setDefaultIsr(31, &isr31);
	//syscall
	setDefaultIsr(128, &isr128);
}

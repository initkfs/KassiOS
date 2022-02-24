/**
 * Authors: initkfs
 */
module os.core.interrupt.isr;

import Irq = os.core.interrupt.irq;

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

//void isr0(); .. void isr31();
static foreach (i; 0 .. 32)
{
	mixin("extern(C) void isr", i, "();");
}

extern (C) __gshared void isr128();

void setDefaultIsr(const ubyte num, void* isr) @nogc
{
	Irq.addDefaultIrqGate(num, isr);
}

void init() @nogc
{
	//setDefaultIsr(0, &isr0); .. setDefaultIsr(31, &isr31);
	static foreach (i; 0 .. 32)
	{
		mixin("setDefaultIsr(", i, ", &isr", i, ");");
	}

	//syscall
	setDefaultIsr(128, &isr128);
}

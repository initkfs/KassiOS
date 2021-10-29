/**
 * Authors: initkfs
 */
module os.core.interrupt.irq;

import Ports = os.core.io.ports;
import Idt = os.core.interrupt.idt;
import Pic = os.core.interrupt.pic;

/*
* https://wiki.osdev.org/Interrupts
*/
enum Interrupts
{
	Timer,
	Keyboard,
	Cascade, //cascade (used internally by the two pics. never raised)
	Com2,
	Com1,
	Lpt2,
	Floppy,
	Lpt1,
	CmosRtc, //cmos real-time clock (if enabled)
	Peripheral1,
	Peripheral2,
	Peripheral3,
	Ps2mouse,
	FpuCoprocessor, //fpu / coprocessor / inter-processor
	Ata1, //primary ata hard disk
	Ata2 //Secondary ATA Hard Disk
}

extern (C) __gshared void irq0();
extern (C) __gshared void irq1();
extern (C) __gshared void irq2();
extern (C) __gshared void irq3();
extern (C) __gshared void irq4();
extern (C) __gshared void irq5();
extern (C) __gshared void irq6();
extern (C) __gshared void irq7();
extern (C) __gshared void irq8();
extern (C) __gshared void irq9();
extern (C) __gshared void irq10();
extern (C) __gshared void irq11();
extern (C) __gshared void irq12();
extern (C) __gshared void irq13();
extern (C) __gshared void irq14();
extern (C) __gshared void irq15();

extern (C) __gshared void isr128();

//https://wiki.osdev.org/Interrupts_tutorial
private void remapIrqs()
{
	Ports.outportb(Pic.Pic1Command, 0x11);
	Ports.outportb(Pic.Pic2Command, 0x11);
	Ports.outportb(Pic.Pic1Data, 0x20);
	Ports.outportb(Pic.Pic2Data, 0x28);
	Ports.outportb(Pic.Pic1Data, 0x04);
	Ports.outportb(Pic.Pic2Data, 0x02);
	Ports.outportb(Pic.Pic1Data, 0x01);
	Ports.outportb(Pic.Pic2Data, 0x01);
	Ports.outportb(Pic.Pic1Data, 0x00);
	Ports.outportb(Pic.Pic2Data, 0x00);
}

void addDefaultIrqGate(const ubyte num, void* irq, const ushort selector = 0x08,
		const ubyte flags = 0x8E)
{
	Idt.addGateToTdt(num, cast(size_t) irq, selector, flags);
}

void init()
{
	remapIrqs;

	addDefaultIrqGate(32, &irq0);
	addDefaultIrqGate(33, &irq1);
	addDefaultIrqGate(34, &irq2);
	addDefaultIrqGate(35, &irq3);
	addDefaultIrqGate(36, &irq4);
	addDefaultIrqGate(37, &irq5);
	addDefaultIrqGate(38, &irq6);
	addDefaultIrqGate(39, &irq7);
	addDefaultIrqGate(40, &irq8);
	addDefaultIrqGate(41, &irq9);
	addDefaultIrqGate(42, &irq10);
	addDefaultIrqGate(43, &irq11);
	addDefaultIrqGate(44, &irq12);
	addDefaultIrqGate(45, &irq13);
	addDefaultIrqGate(46, &irq14);
	addDefaultIrqGate(47, &irq15);
}

void sendInerruptEnd(ulong irq)
{
	if (irq >= 8)
	{
		Ports.outportb(Pic.Pic2Command, Pic.PicEnd);
	}

	Ports.outportb(Pic.Pic1Command, Pic.PicEnd);
}

void enableInterrupts()
{
	asm @trusted
	{
		sti;
	}
}

void disableInterrupts()
{
	asm @trusted
	{
		sti;
	}
}

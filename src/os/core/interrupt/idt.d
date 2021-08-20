/**
 * Authors: initkfs
 * https://wiki.osdev.org/Interrupt_Descriptor_Table
 */
module os.core.interrupt.idt;

__gshared IdtPointer idtPointer;
__gshared Idt64Entry[256] idtEntries;

struct Idt64Entry
{
align(1):
	// offset bits 0..15
	ushort offset1;
	// code segment selector in GDT or LDT
	ushort selector; 
	//its 0..2 holds Interrupt Stack Table offset, rest of bits zero.
	ubyte ist;
	// type and attributes
	ubyte typeAttr; 
	// offset bits 16..31
	ushort offset2; 
	// offset bits 32..63
	uint offset3; 
	// reserved
	uint zero = 0; 
}

struct IdtPointer
{
align(1):
	ushort size;
	ulong base;
}

void addGateToTdt(const ubyte num, const size_t base, const ushort selector, const ubyte flags)
{
	//offset bits 0..15
	idtEntries[num] = Idt64Entry(cast(ushort)(base & 0xFFFF), selector,
			cast(ubyte) 0, flags, cast(ushort)((base >> 16) & 0xFFFF),
			cast(uint)((base >> 32) & 0xFFFFFFFF));
}

void init()
{
	idtPointer.size = cast(ushort)((idtEntries[0].sizeof * 256) - 1);
	idtPointer.base = cast(ulong)&idtEntries;
	void* idtPointerAddr = cast(void*)(&idtPointer);

	asm
	{
		mov RAX, idtPointerAddr;
		lidt [RAX];
		sti;
	}
}

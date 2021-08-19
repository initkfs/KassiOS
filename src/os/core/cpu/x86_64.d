/**
 * Authors: initkfs
 */
module os.core.cpu.x86_64;

void enableSSE()
{
	asm
	{
		mov EAX, CR0;
		and AX, 0xFFFB;
		or AX, 0x2;
		mov CR0, EAX;
		mov EAX, CR4;
		or AX, 3 << 9;
		mov CR4, EAX;
	}
}

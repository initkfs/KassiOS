/**
 * Authors: initkfs
 */
module os.core.io.ports;

void outport(T)(const ushort port, T data)
		if (is(T == ubyte) || is(T == ushort) || is(T == uint))
{
	const uint value = data;

	asm
	{
		mov DX, port;
		mov EAX, value;
	}

	static if (is(T == ubyte))
	{
		asm
		{
			out DX, AL;
		}
	}
	else static if (is(T == ushort))
	{
		asm pure @trusted nothrow @nogc
		{
			out DX, AX;
		}
	}
	else static if (is(T == uint))
	{
		asm pure @trusted nothrow @nogc
		{
			out DX, EAX;
		}
	}
}

void outportb(const ushort port, const ubyte data)
{
	outport!ubyte(port, data);
}

void outportw(const ushort port, const ushort data)
{
	outport!ushort(port, data);
}

void outportd(const ushort port, const uint data)
{
	outport!uint(port, data);
}

T inport(T)(const ushort port) if (is(T == ubyte) || is(T == ushort) || is(T == uint))
{
	T result;

	asm
	{
		mov DX, port;
	}

	//TODO check port
	static if (is(T == ubyte))
	{
		asm
		{
			in AL, DX;
			mov result, AL;
		}
	}
	else static if (is(T == ushort))
	{
		asm @trusted
		{
			in AX, DX;
			mov result, AX;
		}
	}
	else static if (is(T == uint))
	{
		asm @trusted
		{
			in EAX, DX;
			mov result, EAX;
		}
	}

	return result;
}
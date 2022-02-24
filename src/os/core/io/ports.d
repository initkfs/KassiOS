/**
 * Authors: initkfs
 */
module os.core.io.ports;

void outport(T)(const ushort port, T data) @nogc
		if (is(T == ubyte) || is(T == ushort) || is(T == uint))
{
	const uint value = data;

	asm @nogc
	{
		mov DX, port;
		mov EAX, value;
	}

	static if (is(T == ubyte))
	{
		asm @nogc
		{
			out DX, AL;
		}
	}
	else static if (is(T == ushort))
	{
		asm @nogc
		{
			out DX, AX;
		}
	}
	else static if (is(T == uint))
	{
		asm @nogc
		{
			out DX, EAX;
		}
	}
}

void outportb(const ushort port, const ubyte data) @nogc
{
	outport!ubyte(port, data);
}

void outportw(const ushort port, const ushort data) @nogc
{
	outport!ushort(port, data);
}

void outportd(const ushort port, const uint data) @nogc
{
	outport!uint(port, data);
}

T inport(T)(const ushort port) @nogc if (is(T == ubyte) || is(T == ushort) || is(T == uint))
{
	T result;

	asm @nogc
	{
		mov DX, port;
	}

	//TODO check port
	static if (is(T == ubyte))
	{
		asm @nogc
		{
			in AL, DX;
			mov result, AL;
		}
	}
	else static if (is(T == ushort))
	{
		asm @nogc
		{
			in AX, DX;
			mov result, AX;
		}
	}
	else static if (is(T == uint))
	{
		asm @nogc
		{
			in EAX, DX;
			mov result, EAX;
		}
	}

	return result;
}
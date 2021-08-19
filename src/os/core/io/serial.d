/**
 * Authors: initkfs
 * See https://wiki.osdev.org/Serial_Ports
 */
module os.core.io.serial;

private
{
	alias Ports = os.core.io.ports;
	alias Ascii = os.std.text.ascii;
}

private __gshared ushort defaultPort;

enum SerialPorts
{
	COM1 = 0x3F8,
	COM2 = 0x2F8,
	COM3 = 0x3E8,
	COM4 = 0x2E8
}

void initDefaultPort(ushort port = SerialPorts.COM1)
{
	initPort(port);
	defaultPort = port;
}

void initPort(ushort portAddress)
{
	Ports.outportb(cast(ushort)(portAddress + 1), 0x00); // Disable all interrupts
	Ports.outportb(cast(ushort)(portAddress + 3), 0x80); // Enable DLAB
	Ports.outportb(cast(ushort)(portAddress + 0), 0x03); // Set divisor to 3, 38400 baud
	Ports.outportb(cast(ushort)(portAddress + 1), 0x00); // hi byte
	Ports.outportb(cast(ushort)(portAddress + 3), 0x03); // 8 bits, no parity, one stop bit
	Ports.outportb(cast(ushort)(portAddress + 2), 0xC7); // Enable FIFO, clear them, with 14-byte threshold
	Ports.outportb(cast(ushort)(portAddress + 4), 0x0B); // IRQs enabled, RTS/DSR set
}

//TODO check is valid port
bool hasReceived(ushort portAddress = defaultPort)
{
	const ubyte result = Ports.inport!ubyte(cast(ushort)(portAddress + 5)) & 1;
	return result != 0;
}

ubyte read(ushort portAddress = defaultPort)
{
	//TODO limit?
	while (!hasReceived)
	{
	}

	return Ports.inport!ubyte(portAddress);
}

bool transmitIsEmpty(ushort portAddress = defaultPort)
{
	const ubyte result = Ports.inport!ubyte(cast(ushort)(portAddress + 5)) & 0x20;
	return result != 0;
}

void writeln(const string s, ushort portAddress = defaultPort)
{
	foreach (char symbol; s)
	{
		write(symbol, portAddress);
	}

	//TODO from std.file
	write(Ascii.LF, portAddress);
}

void write(const string s, ushort portAddress = defaultPort)
{
	foreach (char symbol; s)
	{
		write(symbol, portAddress);
	}
}

void write(const ubyte a, ushort portAddress = defaultPort)
{
	//TODO limit?
	while (!transmitIsEmpty)
	{
	}

	Ports.outportb(portAddress, a);
}

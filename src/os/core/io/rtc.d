/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/CMOS
module os.core.io.rtc;

private
{
	alias Kstdio = os.std.io.kstdio;
	alias Ports = os.core.io.ports;
}

enum cmosInPort = 0x70;
enum cmosDataPort = 0x71;
enum centuryRegister = 0x00;

enum RtcRegisters
{
	Seconds = 0,
	Minutes = 2,
	Hours = 4,
	DayOfMonth = 7,
	Month = 8,
	Year = 9,
	Century = 0x32,
	RegisterA = 0xA,
	RegisterB = 0xB
}

struct DateTimeRtc
{
	const
	{
		uint century;
		uint year;
		ubyte month;
		ubyte day;
		ubyte hour;
		ubyte minute;
		ubyte second;
	}

	this(const uint century, const uint year, const ubyte month, const ubyte day,
			const ubyte hour, const ubyte minute, const ubyte second)
	{
		//TODO validate
		this.century = century;
		this.year = year;
		this.month = month;
		this.day = day;
		this.hour = hour;
		this.minute = minute;
		this.second = second;
	}
}

ubyte readFromRtcRegister(const ubyte reg)
{
	Ports.outportb(cmosInPort, reg);
	auto rtcValue = Ports.inport!ubyte(cmosDataPort);
	return rtcValue;
}

DateTimeRtc getDateTime()
{
	auto updateCount = 1000;
	while (updateCount > 0)
	{
		const status = readFromRtcRegister(RtcRegisters.RegisterA);
		if (status & 0x80)
		{
			break;
		}
		updateCount--;
	}

	auto second = readFromRtcRegister(RtcRegisters.Seconds);
	auto minute = readFromRtcRegister(RtcRegisters.Minutes);
	auto hour = readFromRtcRegister(RtcRegisters.Hours);
	auto day = readFromRtcRegister(RtcRegisters.DayOfMonth);
	auto month = readFromRtcRegister(RtcRegisters.Month);
	auto year = readFromRtcRegister(RtcRegisters.Year);
	auto century = readFromRtcRegister(RtcRegisters.Century);

	const format = readFromRtcRegister(RtcRegisters.RegisterB);

	//Convert BCD
	if (!(format & 0x4))
	{
		second = (second & 0xf) + (second >> 4) * 10;
		minute = (minute & 0xf) + (minute >> 4) * 10;
		hour = (hour & 0xf) + ((hour & 0x70) >> 4) * 10 + (hour & 0x80);
		day = (day & 0xf) + (day >> 4) * 10;
		month = (month & 0xf) + (month >> 4) * 10;
		year = (year & 0xf) + (year >> 4) * 10;
		century = (century & 0x0F) + ((century / 16) * 10);
	}

	//12 hour clock to 24
	if (!(format & 0x2))
	{
		const ampm = hour & 0x80;
		hour = hour & 0x7f;
		if (hour == 12)
		{
			hour = 0;
		}
		if (ampm)
		{
			hour += 12;
		}
	}

	uint fullYear = year;
	if (century != 0)
	{
		fullYear = 100 * century + year;
	}

	auto dt = DateTimeRtc(century, fullYear, month, day, hour, minute, second);
	return dt;
}

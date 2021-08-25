/**
 * Authors: initkfs
 */
module os.std.util.units;

private
{
	alias Allocator = os.core.mem.allocator;
	alias Strings = os.std.text.strings;
	alias Math = os.std.math.math_core;
}

enum UnitType
{
	SI,
	Binary
}

//TODO round, 1000 TB max
char* formatBytes(size_t bytes, UnitType type = UnitType.SI)
{
	if (bytes == 0)
	{
		return Strings.toStringz("0B");
	}

	size_t oneKInBytes = 0;
	switch (type)
	{
	case UnitType.SI:
		oneKInBytes = 1000;
		break;
	case UnitType.Binary:
		oneKInBytes = 1024;
		break;
	default:
		break;
	}

	const invalidValue = "N/A";

	if (oneKInBytes == 0)
	{
		return Strings.toStringz(invalidValue);
	}

	//TODO SI kB in lower case
	const sizePostfixes = "BKMGT";

	const int postfixIndex = cast(int)(Math.log10(bytes) / Math.log10(oneKInBytes));
	if (postfixIndex >= sizePostfixes.length)
	{
		return Strings.toStringz(invalidValue);
	}

	const double sizeValue = bytes / Math.pow(oneKInBytes, postfixIndex);
	const char sizePostfix = sizePostfixes[postfixIndex];
	const char binaryBytePrefix = 'i';
	const char bytePostfix = 'B';

	char[3] postfixData = [sizePostfix, bytePostfix, 0];
	string postfix = "";
	if (type == UnitType.SI)
	{
		const offset = sizePostfix == bytePostfix ? 2 : 1;
		postfix = cast(string) postfixData.ptr[0 .. postfixData.sizeof - offset];
	}
	else if (type == UnitType.Binary)
	{
		postfixData[1] = binaryBytePrefix;
		postfixData[2] = bytePostfix;
		postfix = cast(string) postfixData.ptr[0 .. postfixData.sizeof];
	}
	//TODO Strings.concat
	auto valuePtr = Strings.toStringz(Math.round(sizeValue, 3), 3);
	string[2] formatArgs = [Strings.toString(valuePtr), postfix];
	auto result = Strings.format("%s%s", formatArgs);
	Allocator.free(valuePtr);
	return result;
}

unittest
{
	import os.std.asserts : kassert;
	import os.std.text.strings : isEquals;

	auto zeroPtr = formatBytes(0);
	auto onePtr = formatBytes(1);
	auto xPtr = formatBytes(999);
	scope(exit){
		Allocator.free(zeroPtr, onePtr, xPtr);
	}

	kassert(isEquals(Strings.toString(zeroPtr), "0B"));
	kassert(isEquals(Strings.toString(onePtr), "1.0B"));
	kassert(isEquals(Strings.toString(xPtr), "999.0B"));

	//TODO round double
}

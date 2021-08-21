/**
 * Authors: initkfs
 */
module os.std.io.kstdio;

private
{
    alias Allocator = os.core.mem.allocator;
    alias Display = os.core.graphic.text_display;
    alias Ascii = os.std.text.ascii;
    alias Strings = os.std.text.strings;
}

void kprintSpace()
{
    kprint(' ');
}

void kprint(const char charValue, const ubyte color = 0b111)
{
    Display.printChar(charValue, color);
}

void kprint(const string str, const ubyte color = 0b111)
{
    Display.printString(str, color);
}

void kprintz(const char* str, const ubyte color = 0b111)
{
    Display.printString(Strings.toString(str), color);
}

void kprintln(const string str = "", const ubyte color = 0b111)
{
    kprint(str, color);
    kprint(Ascii.LF);
}

void kprintlnz(const char* str, const ubyte color = 0b111)
{
    kprintln(Strings.toString(str), color);
}

void kprintf(T)(const string format, const T[] args, const ubyte color = 0b111)
{
    char* result = Strings.format!T(format, args);
    kprintz(result, color);
    Allocator.free(result);
}

void kprintfln(T)(const string format, const T[] args, const ubyte color = 0b111)
{
    kprintf!T(format, args);
    kprint(Ascii.LF);
}

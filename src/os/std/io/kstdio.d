/**
 * Authors: initkfs
 */
module os.std.io.kstdio;

private
{
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

void kprint(const char* str, const ubyte color = 0b111)
{
    Display.printString(Strings.toString(str), color);
}

void kprintln(const string str = "", const ubyte color = 0b111)
{
    kprint(str, color);
    kprint(Ascii.LF);
}

void kprintln(const char* str, const ubyte color = 0b111)
{
    kprintln(Strings.toString(str), color);
}

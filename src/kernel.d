/**
 * Authors: initkfs
 */
module kernel;

import os.std.tests;

//Import is required before aliases
private
{
    alias Ports = os.core.io.ports;
    alias TextDisplay = os.core.graphic.text_display;
    alias Ascii = os.std.text.ascii;
    alias Tests = os.std.tests;
    alias Strings = os.std.text.strings;
}

extern (C) __gshared ulong KERNEL_END;

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{
    Tests.runTest!(Strings);
}

extern (C) __gshared void runInterruptServiceRoutine(const ulong num, const ulong err)
{

}

extern (C) __gshared void runInterruptRequest(const ulong num, const ulong err)
{

}

/**
 * Authors: initkfs
 */
module kernel;

import os.std.tests;

//Import is required before aliases
private
{
    alias CPU = os.core.cpu.x86_64;
    alias Ports = os.core.io.ports;
    alias TextDisplay = os.core.graphic.text_display;
    alias Ascii = os.std.text.ascii;
    alias Tests = os.std.tests;
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Kstdio = os.std.io.kstdio;
    alias LinearList = os.std.container.linear_list;
    alias ArrayList = os.std.container.array_list;
    alias Collections = os.std.container.collections;
    alias MathCore = os.std.math.math_core;
    alias MathRandom = os.std.math.math_random;
}

extern (C) __gshared ulong KERNEL_END;

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{
    //TODO check SSE
    CPU.enableSSE;

    auto memoryStart = cast(ubyte*)(&KERNEL_END + 0x400);
    //TODO parse page tables, 0x6400000 (512 * 50 * 4096)
    auto memoryEnd = cast(ubyte*)(0x6400000 - 0x400);

    TextDisplay.clearScreen;

    Allocator.setMemoryStart(memoryStart);
    Allocator.setMemoryEnd(memoryEnd);

    Tests.runTest!(Allocator);
    Tests.runTest!(Strings);
    Tests.runTest!(LinearList);
    Tests.runTest!(ArrayList);
    Tests.runTest!(Collections);
    Tests.runTest!(MathCore);
    Tests.runTest!(MathRandom);

    size_t usedBytes;
    size_t bufferedBytes;
    size_t availableBytes;

    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);
    Kstdio.kprint(Strings.toString(usedBytes));
}

extern (C) __gshared void runInterruptServiceRoutine(const ulong num, const ulong err)
{

}

extern (C) __gshared void runInterruptRequest(const ulong num, const ulong err)
{

}

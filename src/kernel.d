/**
 * Authors: initkfs
 */
module kernel;

import os.std.tests;

//Import is required before aliases
private
{
    //Core
    alias CoreConfig = os.core.config.core_config;
    alias CPU = os.core.cpu.x86_64;
    alias Ports = os.core.io.ports;
    alias TextDisplay = os.core.graphic.text_display;
    alias Allocator = os.core.mem.allocator;
    alias PCI = os.core.pci.pci_legacy;
    alias RTC = os.core.io.rtc;
    alias Serial = os.core.io.serial;
    alias LoggerCore = os.core.logger.logger_core;
    alias Syslog = os.core.logger.syslog;

    //Std
    alias Tests = os.std.tests;
    alias Ascii = os.std.text.ascii;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;
    alias LinearList = os.std.container.linear_list;
    alias ArrayList = os.std.container.array_list;
    alias Collections = os.std.container.collections;
    alias MathCore = os.std.math.math_core;
    alias MathRandom = os.std.math.math_random;
    alias Datetime = os.std.date.datetime;
    alias SysTime = os.std.date.systime;

    //System
    alias KashLexer = os.sys.kash.lexer;
    alias KashParser = os.sys.kash.parser;
    alias KashExecutor = os.sys.kash.executor;
}

extern (C) __gshared ulong KERNEL_END;

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{
    //TODO check SSE
    CPU.enableSSE;

    auto memoryStart = cast(ubyte*)(&KERNEL_END + 0x400);
    //TODO parse page tables, 0x6400000 (512 * 50 * 4096)
    auto memoryEnd = cast(ubyte*)(0x6400000 - 0x400);

    Allocator.setMemoryStart(memoryStart);
    Allocator.setMemoryEnd(memoryEnd);

    TextDisplay.clearScreen;

    Serial.initDefaultPort;
    Serial.writeln("Serial port enabled");

    Syslog.setLoggerLevel(LoggerCore.LogLevel.all);
    if (Syslog.isTraceLevel)
    {
        string[1] levelArgs = [Syslog.getLoggerLevelName];
        Syslog.tracef("Loaded logger with log level %s", levelArgs);

        size_t[2] memArgs = [cast(size_t) memoryStart, cast(size_t) memoryEnd];
        Syslog.tracef("Set allocator start %x, end %x", memArgs);
    }

    CoreConfig.setLogGeneratedErrors(false);

    Tests.runTest!(Allocator);
    Tests.runTest!(Strings);
    Tests.runTest!(LinearList);
    Tests.runTest!(ArrayList);
    Tests.runTest!(Collections);
    Tests.runTest!(MathCore);
    Tests.runTest!(MathRandom);
    Tests.runTest!(KashLexer);
    Tests.runTest!(KashParser);
    Tests.runTest!(KashExecutor);
    
    CoreConfig.setLogGeneratedErrors(true);

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

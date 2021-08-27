/**
 * Authors: initkfs
 */
module kernel;

import os.std.tests;
import os.std.errors;
import os.std.asserts;

//Import is required before aliases
private
{
    //Core
    alias CoreConfig = os.core.config.core_config;
    alias Multiboot = os.core.boot.multiboot2;
    alias MultibootSpec = os.core.boot.multiboot2spec;
    alias CPU = os.core.cpu.x86_64;
    alias ACPI = os.core.acpi.acpi;
    alias Ports = os.core.io.ports;
    alias TextDisplay = os.core.graphic.text_display;
    alias Keyboard = os.core.io.keyboard;
    alias Allocator = os.core.mem.allocator;
    alias Idt = os.core.interrupt.idt;
    alias Isr = os.core.interrupt.isr;
    alias Irq = os.core.interrupt.irq;
    alias Pic = os.core.interrupt.pic;
    alias PCI = os.core.pci.pci_legacy;
    alias RTC = os.core.io.rtc;
    alias Serial = os.core.io.serial;
    alias LoggerCore = os.core.logger.logger_core;
    alias Syslog = os.core.logger.syslog;

    //Std
    alias Tests = os.std.tests;
    alias Bits = os.std.bits;
    alias Ascii = os.std.text.ascii;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;
    alias LinearList = os.std.container.linear_list;
    alias ArrayList = os.std.container.array_list;
    alias HashMap = os.std.container.hash_map;
    alias Collections = os.std.container.collections;
    alias MathCore = os.std.math.math_core;
    alias MathRandom = os.std.math.math_random;
    alias MathStrict = os.std.math.math_strict;
    alias MathGeometry = os.std.math.math_geometry;
    alias Datetime = os.std.date.datetime;
    alias SysTime = os.std.date.systime;
    alias Units = os.std.util.units;

    //System
    alias KashLexer = os.sys.kash.lexer;
    alias KashParser = os.sys.kash.parser.parser_core;
    alias KashExecutor = os.sys.kash.executor.executor_core;
    alias KashShell = os.sys.kash.shell;
    alias Terminal = os.sys.term;
}

extern (C) __gshared ulong KERNEL_END;

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{

    auto memoryStart = cast(ubyte*)(&KERNEL_END + 0x400);
    //TODO parse page tables, 0x6400000 (512 * 50 * 4096)
    auto memoryEnd = cast(ubyte*)(0x6400000 - 0x800);

    Allocator.setMemoryStart(memoryStart);
    Allocator.setMemoryEnd(memoryEnd);

    enum MULTIBOOT_BOOTLOADER_MAGIC = 0x36d76289;
    if (magic != MULTIBOOT_BOOTLOADER_MAGIC)
    {
        size_t[2] magicArgs = [MULTIBOOT_BOOTLOADER_MAGIC, magic];
        Kstdio.kprintfln("Multiboot-compliant bootloader verification error: magic number expected %x, but received %x. See https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html",
                magicArgs);
        return;
    }

    Isr.init;
    Irq.init;
    Idt.init;

    //TODO check SSE
    CPU.enableSSE;

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

    foreach (Multiboot.multiboot_tag* tag; Multiboot.createTagIterator(multibootInfoAddress))
    {
        switch (tag.type)
        {
        case MultibootSpec.MULTIBOOT_TAG_TYPE_CMDLINE:
            auto cmd = cast(Multiboot.multiboot_tag_string*) tag;
            auto cmdLine = Strings.toString(cast(char*) cmd.string);
            if (cmdLine.length > 0 && Syslog.isTraceLevel)
            {
                string[1] cmdArgs = [cmdLine];
                Syslog.tracef("Multiboot2 found command line: %s", cmdArgs);
            }
            break;
        case MultibootSpec.MULTIBOOT_TAG_TYPE_BASIC_MEMINFO:
            auto memKb = cast(MultibootSpec.multiboot_tag_basic_meminfo*) tag;
            const memUpper = (cast(uint) memKb.mem_upper) * 1000;
            Allocator.setMemoryPhysicalUpper(memUpper);
            if (Syslog.isTraceLevel)
            {
                size_t[1] memArgs = [memUpper];
                Syslog.tracef("Multiboot2 found memory max upper: %l", memArgs);
            }
            break;
        case MultibootSpec.MULTIBOOT_TAG_TYPE_MMAP:
            auto mmapEntryIterator = Multiboot.createMapEntryIterator(
                    cast(MultibootSpec.multiboot_tag_mmap*) tag);
            enum startAddr = 0x100000;
            foreach (entry; mmapEntryIterator)
            {
                if (entry.addr == startAddr && entry.type
                        == MultibootSpec.MULTIBOOT_MEMORY_AVAILABLE)
                {
                    const maxAddr = startAddr + cast(size_t)(entry.len) - 0x400;
                    if (maxAddr > 0 && maxAddr <= cast(size_t) memoryEnd)
                    {
                        Allocator.setMemoryPhysicalEnd(cast(ubyte*) maxAddr);
                        if (Syslog.isTraceLevel)
                        {
                            size_t[1] memArgs = [cast(size_t) maxAddr];
                            Syslog.tracef("Multiboot2 found physical memory end: %x", memArgs);
                        }
                    }
                }
            }
            break;
        default:
            break;
        }
    }

    TextDisplay.clearScreen;

    CoreConfig.setLogGeneratedErrors(false);

    Tests.runTest!(Allocator);
    Tests.runTest!(Strings);
    Tests.runTest!(LinearList);
    Tests.runTest!(ArrayList);
    Tests.runTest!(HashMap);
    Tests.runTest!(Collections);
    Tests.runTest!(MathCore);
    Tests.runTest!(MathRandom);
    Tests.runTest!(MathStrict);
    Tests.runTest!(MathGeometry);
    Tests.runTest!(KashLexer);
    Tests.runTest!(KashParser);
    Tests.runTest!(KashExecutor);
    Tests.runTest!(Units);
    Tests.runTest!(Bits);

    CoreConfig.setLogGeneratedErrors(true);

    KashShell.init;
    Terminal.enable;
    Terminal.start;
}

extern (C) __gshared void runInterruptServiceRoutine(const ulong num, const ulong err)
{
    //TODO Triple Fault
    switch (num)
    {
    case Isr.Exception.DivideByZero:
        panic("Divide by zero exception");
        break;
    case Isr.Exception.Debug:
        panic("Debug trap");
        break;
    case Isr.Exception.Nmi:
        panic("Non Maskable Interrupt");
        break;
    case Isr.Exception.Breakpoint:
        panic("Breakpoint exception");
        break;
    case Isr.Exception.Overflow:
        panic("Overflow exception");
        break;
    case Isr.Exception.BoundRangeExceed:
        panic("Bound Range Exceeded exception");
        break;
    case Isr.Exception.InvalidOpcode:
        panic("Invalid Opcode exception");
        break;
    case Isr.Exception.DeviceNotAvailable:
        panic("Device Not Available exception (check FPU or SSE)");
        break;
    case Isr.Exception.DoubleFault:
        panic("Double Fault exception");
        break;
    case Isr.Exception.InvalidTss:
        panic("Invalid TSS exception");
        break;
    case Isr.Exception.SegmentNotPresent:
        panic("Segment Not Present exception");
        break;
    case Isr.Exception.StackSegmentFault:
        panic("Stack-Segment Fault exception");
        break;
    case Isr.Exception.GeneralProtectionFault:
        panic("General Protection Fault exception");
        break;
    case Isr.Exception.PageFault:
        size_t errorAddr;
        asm
        {
            mov RAX, CR2;
            mov errorAddr, RAX;
        }
        size_t[1] errorArgs = [errorAddr];
        auto errMessagePtr = Strings.format("Page fault: %x", errorArgs);
        scope (exit)
        {
            Allocator.free(errMessagePtr);
        }
        panic(Strings.toString(errMessagePtr));
        break;
    case Isr.Exception.FloatingPointException:
        panic("x87 Floating-Point exception");
        break;
    case Isr.Exception.AlignmentCheck:
        panic("Alignment Check exception");
        break;
    case Isr.Exception.MachineCheck:
        panic("Machine Check exception");
        break;
    case Isr.Exception.SimdFpException:
        panic("SIMD Floating-Point exception");
        break;
    case Isr.Exception.VirtualizationException:
        panic("Virtualization exception");
        break;
    default:
        panic("Unhandled exception");
    }
}

extern (C) __gshared void runInterruptRequest(const ulong num, const ulong err)
{
    //irqs 0-15 are mapped to interrupt service routines 32-47
    immutable uint irq = cast(immutable(uint)) num - 32;
    //be careful about returning before sending interrupt end
    switch (irq)
    {
    case Irq.Interrupts.Timer:
        break;
    case Irq.Interrupts.Keyboard:
        const ubyte keyCode = Keyboard.scanKeyCode;
        if (!Keyboard.isReleased(keyCode) && keyCode != 0) // k == '\?' 
        {
            Terminal.acceptInput(keyCode);
        }
        break;
    default:
    }

    Irq.sendInerruptEnd(num);
}

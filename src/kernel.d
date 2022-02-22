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
    import CoreConfig = os.core.config.core_config;
    import Multiboot = os.core.boot.multiboot2;
    import MultibootSpec = os.core.boot.multiboot2spec;
    import CPU = os.core.cpu.x86_64;
    import ACPI = os.core.acpi.acpi;
    import Ports = os.core.io.ports;
    import TextDisplay = os.core.graphic.text_display;
    import Keyboard = os.core.io.keyboard;
    import Allocator = os.core.mem.allocator;
    import Buffer = os.core.mem.buffer;
    import Idt = os.core.interrupt.idt;
    import Isr = os.core.interrupt.isr;
    import Irq = os.core.interrupt.irq;
    import Pic = os.core.interrupt.pic;
    import PCI = os.core.pci.pci_legacy;
    import RTC = os.core.io.rtc;
    import Serial = os.core.io.serial;
    import LoggerCore = os.core.logger.logger_core;
    import Syslog = os.core.logger.syslog;

    //Std
    import os.std.container.array;

    import Tests = os.std.tests;
    import Bits = os.std.bits;
    import Ascii = os.std.text.ascii;
    import Strings = os.std.text.strings;
    import Hash = os.std.text.hash;
    import Kstdio = os.std.io.kstdio;
    import LinearList = os.std.container.linear_list;
    import ArrayList = os.std.container.array_list;
    import HashMap = os.std.container.hash_map;
    import LinkedList = os.std.container.linked_list;
    import Collections = os.std.container.collections;
    import MathCore = os.std.math.math_core;
    import MathRandom = os.std.math.math_random;
    import MathStrict = os.std.math.math_strict;
    import MathGeometry = os.std.math.math_geometry;
    import Datetime = os.std.date.datetime;
    import SysTime = os.std.date.systime;
    import Units = os.std.util.units;

    //System
    import KashLexer = os.sys.kash.lexer;
    import KashParser = os.sys.kash.parser.parser_core;
    import KashExecutor = os.sys.kash.executor.executor_core;
    import KashNumberExecutor = os.sys.kash.executor.number_expression_executor;
    import KashShell = os.sys.kash.shell;
    import Terminal = os.sys.term;
}

extern (C) __gshared ulong KERNEL_END;

private void runTests()
{
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Start testing modules");
    }

    CoreConfig.setLogGeneratedErrors(false);

    Tests.runTest!(Allocator);
    Tests.runTest!(Strings);
    Tests.runTest!(LinearList);
    Tests.runTest!(ArrayList);
    Tests.runTest!(LinkedList);
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
    Tests.runTest!(KashNumberExecutor);

    CoreConfig.setLogGeneratedErrors(true);

    if (Syslog.isTraceLevel)
    {
        Syslog.trace("End of testing modules");
    }
}

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{
    auto memoryStart = cast(ubyte*)(&KERNEL_END + 0x400);
    //TODO parse page tables, 0x6400000 (512 * 50 * 4096)
    auto memoryEnd = cast(ubyte*)(0x6400000 - 0x800);

    Buffer.setMemoryStart(memoryStart);
    auto memoryBufferEnd = memoryStart + 200;
    Buffer.setMemoryEnd(memoryBufferEnd);

    Allocator.setMemoryStart(memoryBufferEnd);
    Allocator.setMemoryEnd(memoryEnd);

    enum MULTIBOOT_BOOTLOADER_MAGIC = 0x36d76289;
    if (magic != MULTIBOOT_BOOTLOADER_MAGIC)
    {
        Kstdio.kprintfln("Multiboot-compliant bootloader verification error: magic number expected %x, but received %x. See https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html",
                [MULTIBOOT_BOOTLOADER_MAGIC, magic].staticArr);
        return;
    }

    Kstdio.kprint("Hello. ");
    Kstdio.kprint(CoreConfig.osName);
    Kstdio.kprintln(" operating system initialization");

    Kstdio.kprintln("Preparing for interrupt handling");
    Isr.init;
    Irq.init;
    Idt.init;
    Kstdio.kprintln("Interrupt handlers installed");

    //TODO check SSE
    CPU.enableSSE;
    Kstdio.kprintln("SSE enabled");

    Serial.initDefaultPort;
    Serial.writeln("Serial port enabled");

    Syslog.setLoggerLevel(LoggerCore.LogLevel.all);
    //TODO Disable for performance
    //Syslog.setLoad(true);
    if (Syslog.isTraceLevel)
    {
        Syslog.tracef("Loaded logger with log level %s", [Syslog.getLoggerLevelName].staticArr);

        immutable memArgs = [cast(size_t) memoryStart, cast(size_t) memoryEnd].staticArr;
        Syslog.tracef("Set allocator start %x, end %x", memArgs);
    }

    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Preparing for parsing multiboot data");
    }

    foreach (Multiboot.multiboot_tag* tag; Multiboot.createTagIterator(multibootInfoAddress))
    {
        switch (tag.type)
        {
        case MultibootSpec.MULTIBOOT_TAG_TYPE_CMDLINE:
            if (Syslog.isTraceLevel)
            {
                Syslog.trace("Multiboot command line tag found");
            }
            auto cmd = cast(Multiboot.multiboot_tag_string*) tag;
            auto cmdLine = Strings.toString(cast(char*) cmd.string);
            if (Syslog.isTraceLevel)
            {
                if (cmdLine.length > 0)
                {
                    Syslog.tracef("Multiboot command line found: '%s'", [cmdLine].staticArr);

                    const bool isAcpi = !Strings.contains(cmdLine, CoreConfig.noAcpiKernelArgKey);
                    if (Syslog.isTraceLevel)
                    {
                        if (isAcpi)
                        {
                            Syslog.trace("ACPI enabled from kernel command line");
                        }
                        else
                        {
                            Syslog.trace("ACPI disabled from kernel command line");
                        }
                    }

                    CoreConfig.setAcpiEnabled(isAcpi);

                    const bool isKernelTest = !Strings.contains(cmdLine,
                            CoreConfig.noKernelTestArgKey);
                    if (Syslog.isTraceLevel)
                    {
                        if (isKernelTest)
                        {
                            Syslog.trace("Tests enabled from kernel command line");
                        }
                        else
                        {
                            Syslog.trace("Tests disabled from kernel command line");
                        }
                    }

                    CoreConfig.setKernelTestEnabled(isKernelTest);
                }

                Syslog.trace("Multiboot command line parsed");
            }
            break;
        case MultibootSpec.MULTIBOOT_TAG_TYPE_BASIC_MEMINFO:
            if (Syslog.isTraceLevel)
            {
                Syslog.trace("Multiboot memory info tag found");
            }
            auto memKb = cast(MultibootSpec.multiboot_tag_basic_meminfo*) tag;
            const memUpper = (cast(uint) memKb.mem_upper) * 1000;
            Allocator.setMemoryPhysicalUpper(memUpper);
            if (Syslog.isTraceLevel)
            {
                Syslog.tracef("Multiboot memory info parsed. Max upper: %l", [memUpper].staticArr);
            }
            break;
        case MultibootSpec.MULTIBOOT_TAG_TYPE_MMAP:
            if (Syslog.isTraceLevel)
            {
                Syslog.trace("Multiboot memory map tag found");
            }
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
                            Syslog.tracef("Multiboot found physical memory end: %x", [cast(size_t) maxAddr].staticArr);
                        }
                    }
                }
            }

            if (Syslog.isTraceLevel)
            {
                Syslog.trace("Multiboot memory map parsed");
            }
            break;
        default:
            break;
        }
    }

    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Multiboot data parsed");
    }

    if (CoreConfig.isKernelTestEnabled)
    {
        runTests;
    }
    else
    {
        if (Syslog.isTraceLevel)
        {
            Syslog.trace("No testing. Kernel testing disabled in config");
        }
    }

    if (CoreConfig.isAcpiEnabled)
    {
        ACPI.init;
        if (Syslog.isTraceLevel)
        {
            Syslog.trace("ACPI enabled");
        }
    }
    else
    {
        if (Syslog.isTraceLevel)
        {
            Syslog.trace("No ACPI. ACPI disabled in config");
        }
    }

    TextDisplay.clearScreen;
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Clear screen");
    }

    KashShell.init;
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("System shell enabled");
    }

    Terminal.enable;
    Terminal.start;
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Terminal enabled");
    }

    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Operating system initialization completed");
    }
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
        auto errMessagePtr = Strings.format("Page fault: %x", [errorAddr].staticArr);
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

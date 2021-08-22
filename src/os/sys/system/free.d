/**
 * Authors: initkfs
 */
module os.sys.system.free;

private
{
    alias Allocator = os.core.mem.allocator;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;
    alias Units = os.std.util.units;
}

int run(string args, ref char* outResult, ref char* errResult)
{
    Kstdio.kprintln;
    const size_t physEnd = cast(size_t) Allocator.getMemoryPhysicalEnd;
    long[1] physInfo = [physEnd];
    Kstdio.kprintf("Physical memory end %x. ", physInfo);

    Kstdio.kprint("Rough size: ");
    auto sizePtr = Units.formatBytes(Allocator.getMemoryPhysicalUpper);
    Kstdio.kprintz(sizePtr);
    Allocator.free(sizePtr);
    Kstdio.kprintln;

    const size_t allocMemStart = cast(size_t) Allocator.getMemoryStart;
    const size_t allocMemCurrent = cast(size_t) Allocator.getMemoryCurrentPos;
    const size_t allocMemEnd = cast(size_t) Allocator.getMemoryEnd;
    const long[3] allocInfo = [allocMemStart, allocMemCurrent, allocMemEnd];
    Kstdio.kprintfln("Allocator start: %x, current %x, end %x", allocInfo);

    size_t usedBytes;
    size_t bufferedBytes;
    size_t availableBytes;

    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);
    Kstdio.kprint("Used: ");
    auto usedPtr = Units.formatBytes(usedBytes);
    Kstdio.kprintz(usedPtr);
    Allocator.free(usedPtr);

    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);
    Kstdio.kprint(" Buffered: ");
    auto buffPtr = Units.formatBytes(bufferedBytes);
    Kstdio.kprintz(buffPtr);
    Allocator.free(buffPtr);

    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);
    Kstdio.kprint(" Free: ");
    auto freePtr = Units.formatBytes(availableBytes);
    Kstdio.kprintlnz(freePtr);
    Allocator.free(freePtr);
    
    return 0;
}

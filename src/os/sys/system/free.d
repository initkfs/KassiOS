/**
 * Authors: initkfs
 */
module os.sys.system.free;

import os.std.container.hash_map;

private
{
    alias Allocator = os.core.mem.allocator;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;
    alias Units = os.std.util.units;
}

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    Kstdio.kprintln;

    size_t usedBytes, bufferedBytes, availableBytes;
    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);

    const size_t physEnd = cast(size_t) Allocator.getMemoryPhysicalEnd;
    long[1] physInfo = [physEnd];
    Kstdio.kprintf("Physical memory end %x. ", physInfo);

    Kstdio.kprint("Rough size: ");
    auto sizePtr = Units.formatBytes(Allocator.getMemoryPhysicalUpper);
    scope(exit){
        Allocator.free(sizePtr);
    }
    Kstdio.kprintz(sizePtr);
    Kstdio.kprintln;

    const size_t allocMemStart = cast(size_t) Allocator.getMemoryStart;
    const size_t allocMemCurrent = cast(size_t) Allocator.getMemoryCurrentPos;
    const size_t allocMemEnd = cast(size_t) Allocator.getMemoryEnd;
    const long[3] allocInfo = [allocMemStart, allocMemCurrent, allocMemEnd];
    Kstdio.kprintfln("Allocator start: %x, current %x, end %x", allocInfo);

    Kstdio.kprint("Used: ");
    auto usedPtr = Units.formatBytes(usedBytes);
    scope(exit){
        Allocator.free(usedPtr);
    }
    Kstdio.kprintz(usedPtr);

    Kstdio.kprint(" Buffered: ");
    auto buffPtr = Units.formatBytes(bufferedBytes);
    scope(exit){
        Allocator.free(buffPtr);
    }
    Kstdio.kprintz(buffPtr);

    Kstdio.kprint(" Free: ");
    auto freePtr = Units.formatBytes(availableBytes);
    scope(exit){
        Allocator.free(freePtr);
    }
    Kstdio.kprintlnz(freePtr);

    return 0;
}

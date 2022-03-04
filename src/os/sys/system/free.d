/**
 * Authors: initkfs
 */
module os.sys.system.free;

import os.std.container.array;
import os.std.container.hash_map;

import Allocator = os.core.mem.allocator;
import Strings = os.std.text.strings;
import Kstdio = os.std.io.kstdio;
import Units = os.std.util.units;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    Kstdio.kprintln;

    size_t usedBytes, bufferedBytes, availableBytes;
    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);

    const size_t physEnd = cast(size_t) Allocator.getMemoryPhysicalEnd;
    Kstdio.kprintf("Physical memory end %x. ", [physEnd].staticArr);

    Kstdio.kprint("Rough size: ");
    auto sizePtr = Units.formatBytes(Allocator.getMemoryPhysicalUpper);
    scope (exit)
    {
        Allocator.free(sizePtr);
    }
    Kstdio.kprintz(sizePtr);
    Kstdio.kprintln;

    const size_t allocMemStart = cast(size_t) Allocator.getMemoryStart;
    const size_t allocMemCurrent = cast(size_t) Allocator.getMemoryCurrentPos;
    const size_t allocMemEnd = cast(size_t) Allocator.getMemoryEnd;
    Kstdio.kprintfln("Allocator start: %x, current %x, end %x", [
            allocMemStart, allocMemCurrent, allocMemEnd
        ].staticArr);

    Kstdio.kprint("Used: ");
    auto usedPtr = Units.formatBytes(usedBytes);
    scope (exit)
    {
        Allocator.free(usedPtr);
    }
    Kstdio.kprintz(usedPtr);

    Kstdio.kprint(" Buffered: ");
    auto buffPtr = Units.formatBytes(bufferedBytes);
    scope (exit)
    {
        Allocator.free(buffPtr);
    }
    Kstdio.kprintz(buffPtr);

    Kstdio.kprint(" Free: ");
    auto freePtr = Units.formatBytes(availableBytes);
    scope (exit)
    {
        Allocator.free(freePtr);
    }
    Kstdio.kprintlnz(freePtr);

    return Terminal.Result.SUCCESS;
}

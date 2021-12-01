/**
 * Authors: initkfs
 */
module os.core.mem.buffer;

import os.std.errors;
import os.std.asserts;

private __gshared
{
    ubyte* memoryStart;
    ubyte* memoryEnd;
    size_t size;
    bool init;
}

void setMemoryStart(ubyte* value)
{
    kassert(value !is null);
    memoryStart = value;
}

ubyte* getMemoryStart()
{
    kassert(memoryStart !is null);
    return memoryStart;
}

void setMemoryEnd(ubyte* value)
{
    kassert(memoryStart !is null);
    kassert(memoryStart < value);
    kassert(value !is null);
    memoryEnd = value;
    size = memoryEnd - memoryStart;
}

ubyte* getMemoryEnd()
{
    kassert(memoryEnd !is null);
    return memoryEnd;
}

size_t getSize()
{
    return size;
}

void setInit(bool value)
{
    init = value;
}

bool isInit()
{
    return init;
}

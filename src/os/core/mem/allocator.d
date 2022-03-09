/**
 * Authors: initkfs
 */
module os.core.mem.allocator;

import os.std.errors;
import os.std.asserts;

import Syslog = os.core.logger.syslog;

private __gshared
{
    ubyte* memoryStart;
    ubyte* memoryEnd;
    ubyte* memoryCurrentPos;

    ubyte* memoryPhysicalEnd;

    size_t memoryPhysicalUpper;

    MemBlock* heapStart;
    MemBlock* heapCurrent;

    enum MEM_BLOCK_MAGIC_CHECKSUM = 0x7872f0645e696b86;
}

struct MemBlock
{
    align(1):
    MemBlock* next;
    size_t checksum;
    size_t size;
    size_t fullSize;
    bool used;
    size_t[0] data;

    @disable this();
}

size_t* alloc(const size_t requestSizeInBytes, const string file = __FILE__, const int line = __LINE__)
{
    if (Syslog.isLoad)
    {
        //TODO add bytes info
        Syslog.trace("Request allocation", file, line);
    }

    if (requestSizeInBytes == 0)
    {
        panic("Invalid allocation request, size is 0");
    }

    import MathStrict = os.std.math.math_strict;

    size_t buffSize;
    if (const buffSizeErr = MathStrict.addExact(requestSizeInBytes, MemBlock.sizeof, buffSize))
    {
        panic(buffSizeErr);
    }

    kassert(buffSize > 0);

    const size_t size = alignWords(buffSize);

    if (auto block = findFreeMemBlock(requestSizeInBytes))
    {
        block.used = true;
        return block.data.ptr;
    }

    //TODO page fault due addition?
    if (memoryPhysicalEnd !is null && memoryCurrentPos + size >= memoryPhysicalEnd)
    {
        panic(
            "Unable to allocate memory, physical memory limit set, but requested more than available");
    }

    if (size > getMemoryAvailableBytes)
    {
        panic("Unable to allocate memory, requested more than available");
    }

    MemBlock* block = cast(MemBlock*) memoryCurrentPos;
    if (heapStart is null)
    {
        heapStart = block;
    }

    if (heapCurrent !is null)
    {
        heapCurrent.next = block;
    }

    heapCurrent = block;
    block.next = null;
    block.checksum = MEM_BLOCK_MAGIC_CHECKSUM;
    block.size = requestSizeInBytes;
    block.fullSize = size;
    block.used = true;

    incMemoryPos(size);

    if (Syslog.isLoad)
    {
        //TODO add bytes info
        Syslog.trace("Allocation", file, line);
    }

    return block.data.ptr;
}

void free(T...)(const T ptrs, const string file = __FILE__, const int line = __LINE__)
{
    foreach (ptr; ptrs)
    {
        free(ptr);
    }
}

void free(T)(const T* ptr, const string file = __FILE__, const int line = __LINE__)
{
    if (Syslog.isLoad)
    {
        Syslog.trace("Request deallocation", file, line);
    }

    const size_t* dataPtr = cast(size_t*) ptr;
    MemBlock* block = getMemBlockByData(dataPtr);
    if (!block.used)
    {
        panic("The block to be freed has already been released");
    }

    auto blockPtr = cast(ubyte*) dataPtr;
    //TODO more effective 
    foreach (i; 0 .. block.size)
    {
        blockPtr[i] = 0;
    }
    block.used = false;

    if (Syslog.isLoad)
    {
        Syslog.trace("Deallocation", file, line);
    }
}

ubyte* getMemBlockDataEndAddr(const size_t* data)
{
    auto memBlock = getMemBlockByData(data);
    return (cast(ubyte*) data) + memBlock.size;
}

MemBlock* getMemBlockByData(const size_t* data)
{
    import MathStrict = os.std.math.math_strict;
    import os.std.errors;

    //TODO page fault due subtraction?
    auto endAddr = cast(ubyte*) data - MemBlock.data.sizeof;
    auto startAddr = endAddr - MemBlock.sizeof;

    MemBlock* mustBeBlock = cast(MemBlock*)(startAddr);
    if (mustBeBlock.checksum != MEM_BLOCK_MAGIC_CHECKSUM)
    {
        panic("Error. Memory block found with incorrect checksum");
    }
    return mustBeBlock;
}

private MemBlock* findFreeMemBlock(const size_t size)
{
    auto block = heapStart;
    while (block !is null)
    {
        if (block.used || block.size < size)
        {
            block = block.next;
            continue;
        }
        return block;
    }
    return null;
}

void set(T)(T* ptr, T value, const size_t* basePtr)
{
    //TODO ptr == basePtr
    const ubyte* valueStartAddr = cast(ubyte*) ptr;
    if (valueStartAddr < cast(ubyte*) basePtr)
    {
        panic("Unable set value to pointer: pointer address is less than the data start");
    }

    const ubyte* valueEndAddr = valueStartAddr + T.sizeof;
    if (valueEndAddr > getMemBlockDataEndAddr(basePtr))
    {
        panic("Unable set value to pointer. Value size is greater than the data size");
    }
    *ptr = value;
}

void set(T)(T* ptr, T value, const size_t* basePtr, const size_t index)
{
    //TODO check overflow
    const ubyte* valueStartAddr = (cast(ubyte*) ptr) + index * T.sizeof;
    if (valueStartAddr < cast(ubyte*) basePtr)
    {
        panic("Unable set value to pointer with index: value position is less than the data start");
    }
    const ubyte* valueEndAddr = valueStartAddr + T.sizeof;
    if (valueEndAddr > getMemBlockDataEndAddr(basePtr))
    {
        panic(
            "Unable set value to pointer with index: value end address is greater than the data size");
    }
    ptr[index] = value;
}

void setMemoryStart(ubyte* value)
{
    kassert(value !is null);

    if (memoryStart !is null)
    {
        panic("Memory start position already set");
    }

    //TODO check end > start
    memoryStart = value;
    memoryCurrentPos = memoryStart;
}

immutable(ubyte*) getMemoryStart()
{
    kassert(memoryStart !is null);
    immutable(ubyte*) startAddress = cast(immutable(ubyte*)) memoryStart;
    return startAddress;
}

void setMemoryEnd(ubyte* value)
{
    //TODO != memStart, > 0
    kassert(value !is null);

    if (memoryEnd !is null)
    {
        panic("Memory end position already set");
    }

    memoryEnd = value;
}

immutable(ubyte*) getMemoryEnd()
{
    kassert(memoryEnd !is null);
    return cast(immutable(ubyte*)) memoryEnd;
}

void setMemoryPhysicalUpper(const size_t value)
{
    kassert(value > 0);
    memoryPhysicalUpper = value;
}

size_t getMemoryPhysicalUpper()
{
    kassert(memoryPhysicalUpper > 0);
    return memoryPhysicalUpper;
}

void setMemoryPhysicalEnd(ubyte* value)
{
    kassert(value !is null);

    if (memoryPhysicalEnd !is null)
    {
        panic("Physical memory end position already set");
    }

    memoryPhysicalEnd = value;
}

immutable(ubyte*) getMemoryPhysicalEnd()
{
    return cast(immutable(ubyte*)) memoryPhysicalEnd;
}

size_t getMemorySize()
{
    kassert(memoryStart !is null);
    kassert(memoryEnd !is null);

    return memoryEnd - memoryStart;
}

void getMemoryStat(out size_t usedBytes, out size_t bufferedBytes, out size_t avalilableBytes)
{
    avalilableBytes = getMemoryAvailableBytes;
    auto block = heapStart;
    while (block !is null)
    {
        const size_t size = block.size;
        if (block.used)
        {
            usedBytes += size;
        }
        else
        {
            bufferedBytes += size;
        }

        block = block.next;
    }
}

size_t getMemoryAvailableBytes()
{
    kassert(memoryStart !is null);
    kassert(memoryEnd !is null);
    kassert(memoryCurrentPos !is null);

    if (memoryPhysicalEnd !is null)
    {
        return memoryPhysicalEnd - memoryCurrentPos;
    }

    return memoryEnd - memoryCurrentPos;
}

immutable(ubyte*) getMemoryCurrentPos()
{
    kassert(memoryStart !is null);
    kassert(memoryEnd !is null);
    kassert(memoryCurrentPos !is null);

    return cast(immutable(ubyte*)) memoryCurrentPos;
}

void setMemoryCurrentPos(ubyte* value)
{
    kassert(memoryStart !is null);
    kassert(memoryEnd !is null);

    if (value < memoryStart)
    {
        panic("Allocator position is less than the beginning of memory");
    }

    if (value > memoryEnd)
    {
        panic("Allocator position is greater than memory start");
    }

    memoryCurrentPos = value;
}

private void incMemoryPos(const size_t value)
{
    const availableBytes = getMemoryAvailableBytes;
    if (value > availableBytes)
    {
        panic("Unable to increment memory cursor: more memory requested than available");
    }
    memoryCurrentPos += value;
}

private size_t alignWords(size_t n) @nogc pure @safe
{
    return (n + size_t.sizeof - 1) & ~(size_t.sizeof - 1);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(alignWords(1) == 8);
    kassert(alignWords(2) == 8);
    kassert(alignWords(3) == 8);
    kassert(alignWords(8) == 8);
    kassert(alignWords(12) == 16);
    kassert(alignWords(16) == 16);
    kassert(alignWords(31) == 32);
    kassert(alignWords(32) == 32);
}

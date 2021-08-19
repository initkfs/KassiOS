/**
 * Authors: initkfs
 */
module os.core.mem.allocator;

import os.std.errors;
import os.std.asserts;

private
{
    __gshared ubyte* memoryStart;
    __gshared ubyte* memoryEnd;
    __gshared ubyte* memoryCurrentPos;

    __gshared ubyte* memoryPhysicalEnd;

    __gshared size_t memoryPhysicalUpper;

    __gshared MemBlock* heapStart;
    __gshared MemBlock* heapCurrent;

    __gshared const size_t MEM_BLOCK_MAGIC_CHECKSUM = 0x7872f0645e696b86;
}

static struct MemBlock
{
    MemBlock* next;
    size_t checksum;
    size_t size;
    size_t fullSize;
    bool used;
    size_t[1] data;
}

size_t* alloc(size_t requestSizeInBytes)
{
    size_t size = alignWords(requestSizeInBytes) + MemBlock.sizeof;

    if (auto block = findFreeMemBlock(requestSizeInBytes))
    {
        block.used = true;
        return cast(size_t*) block.data.ptr;
    }

    if (memoryPhysicalEnd !is null && (memoryCurrentPos + size) >= memoryPhysicalEnd)
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
    return cast(size_t*) block.data.ptr;
}

void free(T...)(T ptrs)
{
    foreach (ptr; ptrs)
    {
        free(ptr);
    }
}

void free(T)(T* ptr)
{
    size_t* dataPtr = cast(size_t*) ptr;
    MemBlock* block = getMemBlockByData(dataPtr);
    if (!block.used)
    {
        panic("The block to be freed has already been released");
    }
    const size = block.size;
    auto blockPtr = cast(ubyte*) dataPtr;
    foreach (i; 0 .. size)
    {
        blockPtr[i] = 0;
    }
    block.used = false;
}

ubyte* getMemBlockDataEndAddr(size_t* data)
{
    auto memBlock = getMemBlockByData(data);
    return (cast(ubyte*) data) + memBlock.size;
}

MemBlock* getMemBlockByData(size_t* data)
{
    const endAddr = (cast(ubyte*) data) + MemBlock.data.sizeof;
    const startAddr = endAddr - MemBlock.sizeof;
    MemBlock* mustBeBlock = cast(MemBlock*)(startAddr);
    if (mustBeBlock.checksum != MEM_BLOCK_MAGIC_CHECKSUM)
    {
        panic("Error. Memory block found with incorrect checksum");
    }
    return mustBeBlock;
}

private MemBlock* findFreeMemBlock(size_t size)
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

void set(T)(T* ptr, T value, size_t* basePtr)
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

void set(T)(T* ptr, T value, size_t* basePtr, size_t index)
{
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

void setMemoryPhysicalUpper(size_t value)
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

void getMemoryStat(ref size_t usedBytes, ref size_t bufferedBytes, ref size_t avalilableBytes)
{
    avalilableBytes = getMemoryAvailableBytes;
    auto block = heapStart;
    while (block !is null)
    {
        size_t size = block.size;
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

private size_t alignWords(size_t n) @safe pure
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

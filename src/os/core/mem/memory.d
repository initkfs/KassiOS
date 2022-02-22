/**
 * Authors: initkfs
 */
module os.core.mem.memory;

import std.traits;

int memcmp(T)(T* addr1, T* addr2, const size_t size) @nogc pure
{
    for (size_t i = 0; i < size; i++, addr1++, addr2++)
    {
        if (*addr1 < *addr2)
        {
            return -1;
        }
        else if (*addr1 > *addr2)
        {
            return 1;
        }
    }
    return 0;
}

size_t memcp(T)(T* dest, T* src, const size_t n) @nogc pure
{
    if (n == 0)
    {
        return 0;
    }

    if (dest is null || src is null)
    {
        return 0;
    }

    import os.std.math.math_core : abs;

    const availableSize = abs(ptr1 - ptr2);
    if (availableSize >= n)
    {
        foreach (i; 0 .. n)
        {
            dest[i] = src[i];
        }

        return n;
    }

    //TODO copy with buffer

    return 0;
}

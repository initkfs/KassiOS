/**
 * Authors: initkfs
 */
module kernel;

extern (C) __gshared ulong KERNEL_END;

extern (C) void kmain(size_t magic, size_t* multibootInfoAddress)
{

}

extern (C) __gshared void runInterruptServiceRoutine(const ulong num, const ulong err)
{

}

extern (C) __gshared void runInterruptRequest(const ulong num, const ulong err)
{

}
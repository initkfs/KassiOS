/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/ACPI
module os.core.acpi.acpi_core;

bool validate(const ubyte* addr, const size_t size)
{
    ubyte count;
    foreach (b; addr[0 .. size])
    {
        count += b;
    }

    return !count;
}
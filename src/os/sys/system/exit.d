/**
 * Authors: initkfs
 */
module os.sys.system.exit;

import os.std.container.hash_map;

private
{
    alias ACPI = os.core.acpi.acpi;
    alias Ports = os.core.io.ports;
}

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    const bool isAcpiShutdown = ACPI.shutdown;
    if (!isAcpiShutdown)
    {
        //see https://wiki.osdev.org/Shutdown
        //TODO detect emulators
        //Qemu shutdown
        Ports.outportw(0x604, 0x2000);
    }
    return 0;
}

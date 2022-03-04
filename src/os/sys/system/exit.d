/**
 * Authors: initkfs
 */
module os.sys.system.exit;

import os.std.container.hash_map;

import ACPI = os.core.acpi.acpi;
import Ports = os.core.io.ports;
import Terminal = os.sys.term;

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
    return Terminal.Result.SUCCESS;
}

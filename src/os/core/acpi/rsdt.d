/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/RSDT
module os.core.acpi.rsdt;

import AcpiCore = os.core.acpi.acpi_core;
import AcpiRsdp = os.core.acpi.rsdp;
import Memory = os.core.mem.memory;

struct SystemDescriptorTableHeader
{
    char[4] signature;
    uint length;
    ubyte revision;
    ubyte checksum;
    char[6] oemID;
    char[8] oemTableID;
    uint oemRevision;
    char[4] creatorID;
    uint creatorRevision;
}

bool isSdtSignature(ubyte* addr, string sign) @nogc
{
    return Memory.memcmp(addr, cast(ubyte*) sign, sign.length) == 0;
}

SystemDescriptorTableHeader* findTableBySignature(string id, SystemDescriptorTableHeader* rsdt) @nogc
{
    size_t entries = (rsdt.length - SystemDescriptorTableHeader.sizeof) / 4;

    ubyte* entryAddr = cast(ubyte*) rsdt;
    entryAddr += SystemDescriptorTableHeader.sizeof;

    while (entries > 0)
    {
        auto sdt = cast(SystemDescriptorTableHeader*)(*cast(uint*) entryAddr);
        if (sdt is null)
        {
            continue;
        }

        entryAddr += 4;
        entries--;

        auto signature = cast(ubyte*) sdt.signature;
        if (isSdtSignature(signature, id))
        {
            return sdt;
        }
    }

    return null;
}

SystemDescriptorTableHeader* findAcpiRsdt(AcpiRsdp.RootSystemDescriptionPointerV1* rdsp) @nogc
{
    //TODO xsdtAddress
    if (!rdsp.rsdtAddress)
    {
        return null;
    }

    ubyte* rsdtAddr = cast(ubyte*) rdsp.rsdtAddress;
    auto rsdt = cast(SystemDescriptorTableHeader*) rdsp.rsdtAddress;
    if (rsdt.length < SystemDescriptorTableHeader.sizeof)
    {
        return null;
    }

    if (!AcpiCore.validate(rsdtAddr, rsdt.length))
    {
        return null;
    }

    return rsdt;
}

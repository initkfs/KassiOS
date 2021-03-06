/**
 * Authors: initkfs
 */
module os.core.acpi.rsdp;

import AcpiCore = os.core.acpi.acpi_core;

private enum
{
    acpiSignature = 0x2052545020445352,
    acpiQemuLocationAddr = 0xf68c0,
    acpiBiosStartScanAddr = 0x000e0000,
    acpiBiosEndScanAddr = 0x000fffff,
}

//https://wiki.osdev.org/RSDP
//__attribute__ ((packed))
align(1) struct RootSystemDescriptionPointerV1
{
align(1):
    char[8] signature;
    ubyte checksum;
    char[6] oemId;
    ubyte revision;
    uint rsdtAddress;
}

align(1) struct RootSystemDescriptionPointerV2
{
align(1):
    RootSystemDescriptionPointerV1 rdspV1;
    uint length;
    ulong xsdtAddress;
    ubyte extendedChecksum;
    ubyte[3] reserved;
}

private bool isAcpiRsdpSignature(const ubyte* addr) @nogc
{
    return *cast(size_t*) addr == acpiSignature;
}

private RootSystemDescriptionPointerV1* getRsdpFromAddr(const ubyte* addr) @nogc
{
    if (AcpiCore.validate(addr, RootSystemDescriptionPointerV1.sizeof))
    {
        return cast(RootSystemDescriptionPointerV1*) addr;
    }
    return null;
}

RootSystemDescriptionPointerV1* findAcpiRSDP1() @nogc
{
    const mustBeQemuAddr = cast(ubyte*) acpiQemuLocationAddr;
    if (isAcpiRsdpSignature(mustBeQemuAddr))
    {
        auto qemuRsdp = getRsdpFromAddr(mustBeQemuAddr);
        if (qemuRsdp)
        {
            return qemuRsdp;
        }
    }

    auto currentScanAddr = cast(ubyte*) acpiBiosStartScanAddr;
    auto endScanAddr = cast(ubyte*) acpiBiosEndScanAddr;

    while (currentScanAddr < endScanAddr)
    {
        if (isAcpiRsdpSignature(currentScanAddr))
        {
            auto rsdp = getRsdpFromAddr(currentScanAddr);
            if (rsdp)
            {
                return rsdp;
            }
        }

        currentScanAddr += 16;
    }

    return null;
}

/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/ACPI
module os.core.acpi.fadt;

private
{
    alias AcpiRsdt = os.core.acpi.rsdt;
    alias Memory = os.core.mem.memory;

    __gshared bool enabled;
}

struct FixedDescriptionTable
{
    AcpiRsdt.SystemDescriptorTableHeader sdt;
    uint unneded1;
    uint DSDT;
    ubyte[4] unneded2;
    uint SMI_CMD;
    ubyte ACPI_ENABLE;
    ubyte ACPI_DISABLE;
    ubyte[10] unneded3;
    uint PM1a_CNT_BLK;
    uint PM1b_CNT_BLK;
    ubyte[17] unneded4;
    ubyte PM1_CNT_LEN;
    ubyte[18] unneded5;
    ubyte century;
}

__gshared uint PM1a_CNT;
__gshared uint PM1b_CNT;
__gshared uint SLP_TYPa;
__gshared uint SLP_TYPb;
__gshared uint SLP_EN;
__gshared uint SCI_EN;

bool isEnabled()
{
    return enabled;
}

private void setEnabled(bool value)
{
    enabled = value;
}

void setFadt(AcpiRsdt.SystemDescriptorTableHeader* fadtHeader)
{
    setEnabled(false);
    auto fadt = cast(FixedDescriptionTable*) fadtHeader;

    auto dsdtAddr = cast(ubyte*) fadt.DSDT;
    if (!AcpiRsdt.isSdtSignature(dsdtAddr, "DSDT"))
    {
        return;
    }

    //see http://forum.osdev.org/viewtopic.php?t=16990
    enum S5HeaderLength = 36;
    ubyte* S5Addr = dsdtAddr + S5HeaderLength;
    int dsdtLength = (cast(AcpiRsdt.SystemDescriptorTableHeader*) dsdtAddr).length;
    dsdtLength *= 2;
    const softOffStateId = "_S5_";
    while (dsdtLength-- > 0)
    {
        if (Memory.memcmp(S5Addr, cast(ubyte*) softOffStateId, softOffStateId.length) == 0)
        {
            break;
        }
        S5Addr++;
    }

    if (dsdtLength <= 0)
    {
        return;
    }

    //validate AML
    if ((*(S5Addr - 1) == 0x08 || (*(S5Addr - 2) == 0x08 && *(S5Addr - 1) == '\\'))
            && *(S5Addr + 4) == 0x12)
    {
        S5Addr += 5;
        S5Addr += ((*S5Addr & 0xC0) >> 6) + 2;

        if (*S5Addr == 0x0A)
        {
            S5Addr++; // skip byteprefix
        }

        SLP_TYPa = *(S5Addr) << 10;
        S5Addr++;

        if (*S5Addr == 0x0A)
        {
            S5Addr++; // skip byteprefix
        }

        SLP_TYPb = *(S5Addr) << 10;

        auto SMI_CMD = cast(uint*) fadt.SMI_CMD;
        auto ACPI_ENABLE = fadt.ACPI_ENABLE;
        auto ACPI_DISABLE = fadt.ACPI_DISABLE;

        PM1a_CNT = fadt.PM1a_CNT_BLK;
        PM1b_CNT = fadt.PM1b_CNT_BLK;

        auto PM1_CNT_LEN = fadt.PM1_CNT_LEN;

        SLP_EN = 1 << 13;
        SCI_EN = 1;
        setEnabled(true);
    }
}
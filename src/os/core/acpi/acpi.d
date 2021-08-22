/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/ACPI
module os.core.acpi.acpi;

private
{
    alias AcpiRsdp = os.core.acpi.rsdp;
    alias AcpiRsdt = os.core.acpi.rsdt;
    alias AcpiFadt = os.core.acpi.fadt;
}

const apicSignature = "APIC";
const hpetSignature = "HPET";
const fadtSignature = "FACP";

void init()
{
    AcpiRsdp.RootSystemDescriptionPointerV1* rsdp = AcpiRsdp.findAcpiRSDP1;
    if (!rsdp)
    {
        return;
    }

    AcpiRsdt.SystemDescriptorTableHeader* rsdt = AcpiRsdt.findAcpiRsdt(rsdp);
    if (!rsdt)
    {
        return;
    }

    // auto apicTable = AcpiRsdt.findTableBySignature(apicSignature, rsdt);
    // if (apicTable)
    // {
    //     kprintln("Found APIC");
    // }

    // auto hpetTable = AcpiRsdt.findTableBySignature(hpetSignature, rsdt);
    // if (hpetTable)
    // {
    //     kprintln("Found HPET");
    // }

    AcpiRsdt.SystemDescriptorTableHeader* fadtTable = AcpiRsdt.findTableBySignature(fadtSignature, rsdt);
    if (fadtTable)
    {
        AcpiFadt.setFadt(fadtTable);
    }
}

bool shutdown()
{
    if (AcpiFadt.SCI_EN != 1)
    {
        return false;
    }

    alias Ports = os.core.io.ports;

    Ports.outportw(cast(ushort) AcpiFadt.PM1a_CNT, cast(ushort)(AcpiFadt.SLP_TYPa | AcpiFadt.SLP_EN));

    if (AcpiFadt.PM1b_CNT != 0)
    {
        Ports.outportw(cast(ushort) AcpiFadt.PM1b_CNT,
                cast(ushort)(AcpiFadt.SLP_TYPb | AcpiFadt.SLP_EN));
    }

    return true;
}
/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PCI
module os.core.pci.pci_devices;

private
{
	alias Strings = os.std.text.strings;
}


//TODO hashmap;
const string[6] deviceIds = [
	"1234:1111", 
	"8086:100E", 
	"8086:1237", 
	"8086:7000", 
	"8086:7010", 
	"8086:7113"
];
const string[6] deviceNames = [
	"QEMU Virtual Video Controller",
	"82540EM Gigabit Ethernet Controller", 
	"440FX - 82441FX PMC [Natoma]",
	"Name: 82371SB PIIX3 ISA [Natoma/Triton II]",
	"82371SB PIIX3 IDE [Natoma/Triton II]", "82371AB/EB/MB PIIX4 ACPI"
];

string getDeviceName(const string deviceId)
{
	foreach (i, devId; deviceIds)
	{
		if (Strings.isEqual(devId, deviceId) && i < deviceNames.length)
		{
			string deviceName = deviceNames[i];
			return deviceName;
		}
	}
	return null;
}

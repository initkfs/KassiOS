/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PCI
module os.core.pci.pci_legacy;

import Ports = os.core.io.ports;

struct PciConfigSpace
{
	enum configAddress = 0xCF8;
	enum configData = 0xCFC;
}

uint readConfig(ushort bus, ushort slot, ushort func, ushort offset) @nogc
{
	uint address = cast(uint)(
			(bus << 16) | (slot << 11) | (func << 8) | (offset & 0xfc) | (cast(uint) 0x80000000));
	Ports.outportd(PciConfigSpace.configAddress, address);
	auto pciData = Ports.inport!uint(PciConfigSpace.configData);
	//& 0xffff
	return cast(ushort)(pciData >> ((offset & 2) * 8));
}

uint getVendorID(ushort bus, ushort device, ushort func) @nogc
{
	const vendorId = readConfig(bus, device, func, 0);
	return vendorId;
}

uint getDeviceID(ushort bus, ushort device, ushort func) @nogc
{
	const deviceId = readConfig(bus, device, func, 2);
	return deviceId;
}

bool isDeviceExists(ushort bus, ushort slot, ushort func = 0) @nogc
{
	return readConfig(bus, slot, func, 0) != ushort.max;
}

void iteratePciDevices(scope void delegate(uint, uint) onDeviceIdAndVendor)
{
	for (ushort bus = 0; bus < 256; bus++)
	{
		for (ushort slot = 0; slot < 32; slot++)
		{
			for (ushort func = 0; func < 8; func++)
			{
				if (!isDeviceExists(bus, slot, func))
				{
					continue;
				}

				const vendorId = getVendorID(bus, slot, func);
				const deviceId = getDeviceID(bus, slot, func);
				onDeviceIdAndVendor(deviceId, vendorId);
			}
		}
	}
}

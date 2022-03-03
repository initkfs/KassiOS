/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PCI
module os.core.config.core_config;

private __gshared
{
	bool logGeneratedErrors;
	bool acpiEnabled = true;
	bool kernelTestEnabled = true;
}

const
{
	string osName = "KassiOS";
	string osVersion = "0.1a";

	string noAcpiKernelArgKey = "noacpi";
	string noKernelTestArgKey = "notests";
}

void setAcpiEnabled(bool value) @nogc
{
	acpiEnabled = value;
}

bool isAcpiEnabled() @nogc
{
	return acpiEnabled;
}

void setKernelTestEnabled(bool value) @nogc
{
	kernelTestEnabled = value;
}

bool isKernelTestEnabled() @nogc
{
	return kernelTestEnabled;
}

void setLogGeneratedErrors(bool value) @nogc
{
	logGeneratedErrors = value;
}

bool isLogGeneratedErrors() @nogc
{
	return logGeneratedErrors;
}

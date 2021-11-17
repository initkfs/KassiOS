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

void setAcpiEnabled(bool value)
{
	acpiEnabled = value;
}

bool isAcpiEnabled()
{
	return acpiEnabled;
}

void setKernelTestEnabled(bool value)
{
	kernelTestEnabled = value;
}

bool isKernelTestEnabled()
{
	return kernelTestEnabled;
}

void setLogGeneratedErrors(bool value)
{
	logGeneratedErrors = value;
}

bool isLogGeneratedErrors()
{
	return logGeneratedErrors;
}

/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PCI
module os.core.config.core_config;

private
{
	__gshared bool logGeneratedErrors;
}

void setLogGeneratedErrors(bool value)
{
	logGeneratedErrors = value;
}

bool isLogGeneratedErrors()
{
	return logGeneratedErrors;
}

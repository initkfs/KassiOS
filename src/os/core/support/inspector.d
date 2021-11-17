/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PCI
module os.core.support.inspector;

private __gshared
{
	bool errors;
}

bool isErrors()
{
	return errors;
}

void setErrors()
{
	errors = true;
}

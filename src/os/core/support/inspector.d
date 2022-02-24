/**
 * Authors: initkfs
 */
module os.core.support.inspector;

private __gshared
{
	bool errors;
}

bool isErrors() @nogc
{
	return errors;
}

void setErrors() @nogc
{
	errors = true;
}

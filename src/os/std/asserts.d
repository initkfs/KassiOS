/**
 * Authors: initkfs
 */
module os.std.asserts;

import os.std.errors;

public void kassert(const bool condition, const string file = __FILE__, const int line = __LINE__)
{
	if (!condition)
	{
		panic("Assertion failed", file, line);
	}
}

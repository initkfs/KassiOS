/**
 * Authors: initkfs
 */
module os.std.tests;

void runTest(alias anyModule)()
{
	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, anyModule))
	{
		unitTestFunction();
	}
}

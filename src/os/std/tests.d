/**
 * Authors: initkfs
 */
module os.std.tests;

private
{
	alias Syslog = os.core.logger.syslog;
}

void runTest(alias anyModule)()
{
	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, anyModule))
	{
		unitTestFunction();
	}

	if (Syslog.isTraceLevel)
	{
		string[1] moduleNameArgs = [anyModule.stringof];
		Syslog.tracef("Test module %s", moduleNameArgs);
	}
}

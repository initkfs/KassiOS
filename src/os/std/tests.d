/**
 * Authors: initkfs
 */
module os.std.tests;

import Syslog = os.core.logger.syslog;

void runTest(alias testModule)()
{
	if (Syslog.isTraceLevel)
	{
		string[1] moduleNameArgs = [testModule.stringof];
		Syslog.tracef("Start testing %s", moduleNameArgs);
	}

	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, testModule))
	{
		unitTestFunction();
	}

	if (Syslog.isTraceLevel)
	{
		string[1] moduleNameArgs = [testModule.stringof];
		Syslog.tracef("Test %s", moduleNameArgs);
	}
}

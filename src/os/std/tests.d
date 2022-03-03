/**
 * Authors: initkfs
 */
module os.std.tests;

import Syslog = os.core.logger.syslog;

import os.std.container.array;

void runTest(alias testModule)()
{
	if (Syslog.isTraceLevel)
	{
		Syslog.tracef("Start testing %s", [testModule.stringof].staticArr);
	}

	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, testModule))
	{
		unitTestFunction();
	}

	if (Syslog.isTraceLevel)
	{
		Syslog.tracef("End testing %s", [testModule.stringof].staticArr);
	}
}

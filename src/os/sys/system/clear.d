/**
 * Authors: initkfs
 */
module os.sys.system.clear;

private
{
    alias Terminal = os.sys.term;
}

int run(string args, ref char* outResult, ref char* errResult)
{
    Terminal.clearScreen;
    return 0;
}

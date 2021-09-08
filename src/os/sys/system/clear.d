/**
 * Authors: initkfs
 */
module os.sys.system.clear;

import os.std.container.hash_map;

private
{
    alias Terminal = os.sys.term;
}

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    Terminal.clearScreen;
    return 0;
}

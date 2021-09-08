/**
 * Authors: initkfs
 */
module os.sys.fs.ls;

import os.std.container.hash_map;

private
{
    alias Fs = os.core.fs.memfs.memfs;
}

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    Fs.list;
    return 0;
}

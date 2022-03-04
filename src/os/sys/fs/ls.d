/**
 * Authors: initkfs
 */
module os.sys.fs.ls;

import os.std.container.hash_map;

import Fs = os.core.fs.memfs.memfs;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    Fs.list;
    return Terminal.Result.SUCCESS;
}

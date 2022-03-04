/**
 * Authors: initkfs
 */
module os.sys.fs.mount;

import os.std.container.array;
import os.std.container.hash_map;

import Fs = os.core.fs.memfs.memfs;
import Strings = os.std.text.strings;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    if (Fs.isMount)
    {
        errResult = Strings.toStringz("The file system is already mounted");
        return Terminal.Result.ERROR;
    }
    Fs.mount;
    if (Fs.isMount)
    {
        outResult = Strings.format("Mount %s as %s", [
                Fs.getRootParitionId, Fs.getRootMountPoint
            ].staticArr);
    }
    else
    {
        errResult = Strings.toStringz("Failed to mount filesystem");
        return Terminal.Result.ERROR;
    }
    return Terminal.Result.SUCCESS;
}

/**
 * Authors: initkfs
 */
module os.sys.fs.mount;

import os.std.container.hash_map;

import Fs = os.core.fs.memfs.memfs;
import Strings = os.std.text.strings;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    if (Fs.isMount)
    {
        errResult = Strings.toStringz("The file system is already mounted");
        return -1;
    }
    Fs.mount;
    if (Fs.isMount)
    {
        string[2] mountArgs = [Fs.getRootParitionId, Fs.getRootMountPoint];
        outResult = Strings.format("Mount %s as %s", mountArgs);
    }
    else
    {
        errResult = Strings.toStringz("Failed to mount filesystem");
        return -1;
    }
    return 0;
}

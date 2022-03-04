/**
 * Authors: initkfs
 */
module os.sys.fs.unmount;

import os.std.container.hash_map;

import Fs = os.core.fs.memfs.memfs;
import Strings = os.std.text.strings;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    if (!Fs.isMount)
    {
        errResult = Strings.toStringz("File system not mounted");
        return Terminal.Result.ERROR;
    }
    Fs.unmount;
    if (!Fs.isMount)
    {
        outResult = Strings.toStringz("Unmount all filesystems");
    }
    else
    {
        errResult = Strings.toStringz("Failed to unmount filesystem");
        return Terminal.Result.ERROR;
    }

    return Terminal.Result.SUCCESS;
}

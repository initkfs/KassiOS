/**
 * Authors: initkfs
 */
module os.sys.fs.mkfile;

import os.std.container.hash_map;

import Fs = os.core.fs.memfs.memfs;
import Strings = os.std.text.strings;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    string filename = "hello.txt";
    const bool isCreated = Fs.createFile(filename);
    if (isCreated)
    {
        string[1] fsArgs = [filename];
        outResult = Strings.format("Created file %s", fsArgs);
    }
    else
    {
        errResult = Strings.toStringz("Error. The file could not be created");
    }
    return Terminal.Result.SUCCESS;
}

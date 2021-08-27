/**
 * Authors: initkfs
 */
module os.sys.fs.ls;

private
{
    alias Fs = os.core.fs.memfs.memfs;
}

int run(string args, ref char* outResult, ref char* errResult)
{
    Fs.list;
    return 0;
}

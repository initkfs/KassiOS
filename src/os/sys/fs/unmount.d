/**
 * Authors: initkfs
 */
module os.sys.fs.unmount;

private
{
    alias Fs = os.core.fs.memfs.memfs;
    alias Strings = os.std.text.strings;
}

int run(string args, ref char* outResult, ref char* errResult)
{
    if (!Fs.isMount)
    {
        errResult = Strings.toStringz("File system not mounted");
        return -1;
    }
    Fs.unmount;
    if (!Fs.isMount)
    {
        outResult = Strings.toStringz("Unmount all filesystems");
    }
    else
    {
        errResult = Strings.toStringz("Failed to unmount filesystem");
        return -1;
    }
    return 0;
}

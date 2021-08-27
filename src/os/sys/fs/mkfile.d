/**
 * Authors: initkfs
 */
module os.sys.fs.mkfile;

private
{
    alias Fs = os.core.fs.memfs.memfs;
    alias Strings = os.std.text.strings;
}

int run(string args, ref char* outResult, ref char* errResult)
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
    return 0;
}

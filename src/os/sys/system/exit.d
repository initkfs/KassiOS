/**
 * Authors: initkfs
 */
module os.sys.system.exit;

private {
    alias Strings = os.std.text.strings;
}

int run(string args, ref char* outResult, ref char* errResult){
    import os.std.io.kstdio;
    import os.std.text.strings;
    outResult = Strings.toStringz("Exit!");
    errResult = null;

    return 0;
}
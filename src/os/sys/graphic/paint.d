/**
 * Authors: initkfs
 */
module os.sys.graphic.paint;

import os.std.container.hash_map;
import KStdio = os.std.io.kstdio;
import Painter = os.sys.graphic.ascii.ascii_painter;
import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    KStdio.kprintln;
    //must be even for some shapes
    enum defaultSize = 4;
    if (args.containsKey("s"))
    {
        Painter.drawSierpinski(defaultSize);
    }
    else if (args.containsKey("c"))
    {
        Painter.drawCircle(defaultSize);
    }
    return Terminal.Result.SUCCESS;
}

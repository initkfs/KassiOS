/**
 * Authors: initkfs
 */
module os.sys.media.beep;

import Speaker = os.core.io.speaker;
import os.std.container.hash_map;

import Terminal = os.sys.term;

int run(HashMap* args, ref char* outResult, ref char* errResult)
{
    //TODO pause timer\sleep
    Speaker.soundPlay(1000);
    size_t ticks = 10_000_000;
    while (ticks)
    {
        ticks--;
    }
    Speaker.soundDisable;
    return Terminal.Result.SUCCESS;
}

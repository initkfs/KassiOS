/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/PC_Speaker
module os.core.io.speaker;

import Ports = os.core.io.ports;

static void soundPlay(uint frequence) @nogc
{
    immutable uint desiredFrequency = 1_193_180 / frequence;
    Ports.outportb(0x43, 0xb6);
    Ports.outportb(0x42, cast(ubyte)(desiredFrequency));
    Ports.outportb(0x42, cast(ubyte)(desiredFrequency >> 8));

    immutable ubyte speakerIn = Ports.inport!ubyte(0x61);
    if (speakerIn != (speakerIn | 3))
    {
        Ports.outportb(0x61, speakerIn | 3);
    }
}

void soundDisable() @nogc
{
    immutable ubyte speakerIn = Ports.inport!ubyte(0x61);
    Ports.outportb(0x61, speakerIn & 0xFC);
}

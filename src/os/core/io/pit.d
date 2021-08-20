/**
 * Authors: initkfs
 */
//https://wiki.osdev.org/Programmable_Interval_Timer
module os.core.io.pit;

private
{
    alias Ports = os.core.io.ports;
}

//1.19MHz
enum OscillatorFrequencyHz = 1_193_180;
enum Channel0DataPort = 0x40;
enum Channel1DataPort = 0x41;
enum Channel2DataPort = 0x42;
enum ModeWriteRegister = 0x43;

void setTimerFrequencyHz(uint hz)
{
    const uint requestHz = hz == 0 ? 1 : hz;
    const uint divisor = OscillatorFrequencyHz / requestHz;
    Ports.outportb(ModeWriteRegister, 0x36);
    Ports.outportb(Channel0DataPort, cast(ubyte)(divisor & 0xFF));
    Ports.outportb(Channel0DataPort, cast(ubyte)(divisor >> 8));
}

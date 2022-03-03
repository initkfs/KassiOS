/**
 * Authors: initkfs
 */
module os.core.interrupt.pic;

import Ports = os.core.io.ports;

//https://wiki.osdev.org/8259_PIC
//TODO APIC https://wiki.osdev.org/APIC

enum
{
    Pic1 = 0x20,
    Pic1Command = Pic1,
    Pic1Data = Pic1 + 1,
}

enum
{
    Pic2 = 0xA0,
    Pic2Command = Pic2,
    Pic2Data = Pic2 + 1,
}

enum
{
    Timer0 = 0x40,
    Timer1 = 0x41,
    Timer2 = 0x42,
    TimerMode = 0x43,
}

enum PicEnd = 0x20; /* End-of-interrupt command code */

void sendEndPic1() @nogc
{
    Ports.outportb(Pic1Command, PicEnd);
}

void sendEndPic2() @nogc
{
    Ports.outportb(Pic2Command, Pic2);
}

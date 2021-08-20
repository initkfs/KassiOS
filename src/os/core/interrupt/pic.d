/**
 * Authors: initkfs
 */
module os.core.interrupt.pic;

private {
    alias Ports = os.core.io.ports;
}

//https://wiki.osdev.org/8259_PIC
//TODO APIC https://wiki.osdev.org/APIC
enum Pic1 = 0x20;
enum Pic2 = 0xA0;
enum Pic1Command = Pic1;
enum Pic1Data = Pic1 + 1;
enum Pic2Command = Pic2;
enum Pic2Data = Pic2 + 1;

enum PicEnd = 0x20; /* End-of-interrupt command code */

enum Timer0 = 0x40;
enum Timer1 = 0x41;
enum Timer2 = 0x42;
enum TimerMode = 0x43;

void sendEndPic1()
{
    Ports.outportb(Pic1Command, PicEnd);
}

void sendEndPic2()
{
    Ports.outportb(Pic2Command, Pic2);
}

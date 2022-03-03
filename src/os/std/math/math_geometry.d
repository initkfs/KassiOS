/**
 * Authors: initkfs
 */
module os.std.math.math_geometry;

import std.traits;

import MathCore = os.std.math.math_core;

enum
{
    Pi = 3.14159265358979323846,
    RadiansInDeg = 0.017453292519943295,
    DegInRadians = 57.29577951308232,
}

double toRadians(double angleValueDeg) @nogc pure @safe
{
    return angleValueDeg * RadiansInDeg;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEquals(toRadians(10), 0.17453292519943293));
}

double toDegrees(double angleValueRad) @nogc pure @safe
{
    return angleValueRad * DegInRadians;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEquals(toDegrees(0.15), 8.59436692696234769));
}

//TODO check bounds
double sin(double radValue) @nogc
{
    double result;
    asm @nogc
    {
        //TODO check soprocessor errors
        fld radValue;
        fsin;
        fstp qword ptr[result];
    }
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEquals(sin(-0.4), -0.3894183423086505));
    kassert(MathCore.isEquals(sin(1), 0.8414709848078965));
}

double cos(double radValue) @nogc
{
    double result;
    asm @nogc
    {
        fld radValue;
        fcos;
        fstp qword ptr[result];
    }
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEquals(cos(10), -0.8390715290764524));
    kassert(MathCore.isEquals(cos(1), 0.5403023058681398));
}

double tan(double radValue) @nogc
{
    return sin(radValue) / cos(radValue);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEquals(tan(1), 1.55740772465490205));
    kassert(MathCore.isEquals(tan(2), -2.185039863261519));
}

/**
 * Authors: initkfs
 */
module os.std.math.math_geometry;

import std.traits;

private
{
    alias MathCore = os.std.math.math_core;
}

enum Pi = 3.14159265358979323846;
enum RadiansInDeg = 0.017453292519943295;
enum DegInRadians = 57.29577951308232;

double toRadians(double angleValueDeg)
{
    return angleValueDeg * RadiansInDeg;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEqual(toRadians(10), 0.17453292519943293));
}

double toDegrees(double angleValueRad)
{
    return angleValueRad * DegInRadians;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEqual(toDegrees(0.15), 8.59436692696234769));
}

//TODO check bounds
double sin(double radValue)
{
    double result;
    asm
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

    kassert(MathCore.isEqual(sin(-0.4), -0.3894183423086505));
    kassert(MathCore.isEqual(sin(1), 0.8414709848078965));
}

double cos(double radValue)
{
    double result;
    asm
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

    kassert(MathCore.isEqual(cos(10), -0.8390715290764524));
    kassert(MathCore.isEqual(cos(1), 0.5403023058681398));
}

double tan(double radValue)
{
    return sin(radValue) / cos(radValue);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(MathCore.isEqual(tan(1), 1.55740772465490205));
    kassert(MathCore.isEqual(tan(2), -2.185039863261519));
}
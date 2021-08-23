/**
 * Authors: initkfs
 */
module os.std.math.math_core;

import std.traits;

private
{
    alias Strings = os.std.text.strings;
    alias Ascii = os.std.text.ascii;

}

struct Epsilon
{
    static const float FLOAT_EPSILON = 1.19e-07;
    static const double DOUBLE_EPSILON = 2.20e-16;
}

T abs(T)(T x) if (isFloatingPoint!(T) || isIntegral!(T))
{
    if (x < 0)
    {
        return -x;
    }

    return x;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(abs(0) == 0);
    kassert(abs(-1) == 1);
    kassert(abs(-2345) == 2345);
    kassert(abs(-1.0) == 1.0);
}

bool isEqualEps(T)(T x, T y, T epsilon) if (isFloatingPoint!(T))
{
    if (abs(x - y) < epsilon)
    {
        return true;
    }
    return false;
}

bool isEqual(float x, float y)
{
    return isEqualEps(x, y, Epsilon.FLOAT_EPSILON);
}

bool isEqual(double x, double y)
{
    return isEqualEps(x, y, Epsilon.DOUBLE_EPSILON);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEqual(0.0, 0.0));
    kassert(!isEqual(0.0, 0.1));
    kassert(isEqual(0.3, 0.3));
    kassert(!isEqual(0.3, 0.3000000000000004));
    kassert(isEqual(0.3, 0.30000000000000004));
}

double sqrt(double value)
{
    //or NaN?
    if (value == 0)
    {
        return 0;
    }

    if (value < 0)
    {
        return double.nan;
    }

    double result;
    asm
    {
        fld value;
        fsqrt;
        fstp qword ptr[result];
    }
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(sqrt(0) == 0);
    kassert(isNaN(sqrt(-1)));
    kassert(sqrt(1) == 1);
    kassert(sqrt(4) == 2);
    kassert(sqrt(16) == 4);
    kassert(sqrt(169) == 13);
    kassert(sqrt(0.0004) == 0.02);
    kassert(sqrt(9.6) == 3.0983866769659336);
}

double pow(const double base, const long exponent) pure @safe nothrow
{
    //0^0 must be an error
    if (base == 0)
    {
        return 0;
    }

    if (exponent == 0)
    {
        return 1;
    }

    if (exponent == 1)
    {
        return base;
    }

    const result = pow(base, exponent / 2);
    const mod2Exp = exponent % 2;
    if (mod2Exp < 0)
    {
        return result * result / base;
    }

    else if (mod2Exp > 0)
    {
        return result * result * base;
    }

    return result * result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(pow(0, 0) == 0);
    kassert(pow(1, 1) == 1);
    kassert(pow(2, 2) == 4);
    kassert(pow(2, 3) == 8);
    kassert(pow(2.5, 3) == 15.625);
    kassert(pow(10, -1) == 0.1);
    kassert(isEqual(pow(10, -2), 0.01));
    kassert(isEqual(pow(10, -3), 0.001));
}

bool isPositiveInf(T)(T x) if (isFloatingPoint!(T))
{
    return x == x.infinity;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(!isPositiveInf(0.0));
    kassert(isPositiveInf(double.infinity));
    kassert(!isPositiveInf(-double.infinity));
}

bool isNegativeInf(T)(T x) if (isFloatingPoint!(T))
{
    return x == -x.infinity;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(!isNegativeInf(0.0));
    kassert(isNegativeInf(-double.infinity));
    kassert(!isNegativeInf(double.infinity));
}

bool isInf(T)(T x) if (isFloatingPoint!(T))
{

    return isPositiveInf(x) || isNegativeInf(x);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(!isInf(0.0));
    kassert(isInf(double.infinity));
    kassert(isInf(3.4 / 0));
}

bool isNaN(T)(T value) if (isFloatingPoint!(T))
{
    return value != value;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(!isNaN(0.0));
    kassert(!isNaN(1.0));
    kassert(!isNaN(double.infinity));
    kassert(!isNaN(-double.infinity));

    kassert(isNaN(double.nan));
}

bool isFinite(T)(T x) if (isFloatingPoint!(T))
{
    return x == x && !isNaN(x) && !isInf(x);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isFinite(0.0));
    kassert(isFinite(0.00000000001));
    kassert(!isFinite(double.nan));
    kassert(!isFinite(double.infinity));
    kassert(!isFinite(-double.infinity));
    kassert(!isFinite(float.nan));
}

//log_y(x) = log_a(x) / log_a(y)
//log10(x) = log2(x)/log2(10)
double log10(double x)
{

    if (x <= 0 || !isFinite(x))
    {
        return double.nan;
    }

    double result = log2(x) / log2(10);
    return result;
    //asm
    // {
    //     fld1;
    //     fld x;
    //     fyl2x;
    //     fldl2t;
    //     fdivp;
    //     fstp qword ptr[result];
    // }
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isNaN(log10(0)));
    kassert(log10(0.5) == 0);
    kassert(log10(1) == 0);
    kassert(isEqual(log10(2.0), 0.3010299956639812));
    kassert(isEqual(log10(3.4), 0.5314789170422551));
}

double log2(double x)
{

    if (x <= 1 || !isFinite(x))
    {
        return 0;
    }

    double result;
    asm
    {
        fld1;
        fld x;
        fyl2x;
        fstp qword ptr[result];
    }
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(log2(0) == 0);
    kassert(log2(0.5) == 0);
    kassert(log2(1.0) == 0);
    kassert(isEqual(log2(1.2), 0.26303440583379375));
    kassert(isEqual(log2(3.0), 1.58496250072115628));
}

double floor(double x)
{
    if (!isFinite(x))
    {
        return double.nan;
    }
    if (x >= 0)
    {
        return cast(double) cast(int) x;
    }

    auto intValue = cast(int) x;
    return (isEqual(cast(double) intValue, x)) ? intValue : intValue - 1;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(floor(0.0) == 0);
    kassert(floor(1.0) == 1.0);
    kassert(floor(-2.0) == -2.0);
    kassert(floor(12.567) == 12.0);
    kassert(floor(4.3) == 4);
    kassert(floor(2.55 / 1.0) == 2);
}

//TODO e-notation
double parseDouble(string str, const char separator = '.')
{
    if (str.length == 0)
    {
        return double.nan;
    }

    if (Strings.isEqual(str, "NaN"))
    {
        return double.nan;
    }

    if (Strings.isEqual(str, "+Infinity"))
    {
        return double.infinity;
    }

    if (Strings.isEqual(str, "-Infinity"))
    {
        return -double.infinity;
    }

    double result = 0.0;
    int e = 0;
    size_t currentCharIndex;
    const isNeg = (str[0] == '-');
    if (isNeg)
    {
        currentCharIndex++;
    }

    foreach (i; currentCharIndex .. (str.length))
    {
        const ch = str[i];
        if (!Ascii.isDecimalDigit(ch))
        {
            break;
        }
        currentCharIndex++;
        result = result * 10 + (ch - '0');
    }

    const mustBeSep = str[currentCharIndex];
    if (mustBeSep == separator)
    {
        const fromSepToEnd = currentCharIndex + 1;
        foreach (i; fromSepToEnd .. (str.length))
        {
            const ch = str[i];
            if (!Ascii.isDecimalDigit(ch))
            {
                break;
            }
            result = result * 10 + (ch - '0');
            e = e - 1;
            currentCharIndex++;
        }
    }

    while (e > 0)
    {
        result *= 10;
        e--;
    }

    while (e < 0)
    {
        result *= 0.1;
        e++;
    }

    return isNeg ? -result : result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isNaN(parseDouble("NaN")));
    kassert(isPositiveInf(parseDouble("+Infinity")));
    kassert(isNegativeInf(parseDouble("-Infinity")));
    kassert(isEqual(parseDouble("0.0"), 0.0));
    kassert(isEqual(parseDouble("3.556"), 3.55600000000000048));
    kassert(isEqual(parseDouble("564.63333"), 564.63333000000022811));
}

//TODO unittest
size_t roundToIntegral(double value)
{
    if (isNaN(value))
    {
        return 0;
    }
    //TODO max value, min value overflow
    if (value > 0)
    {
        return cast(size_t)(value + 0.5);
    }
    else
    {
        return cast(size_t)(value - 0.5);
    }
}

//TODO unittest
double round(double value, size_t precision)
{
    return pow(10, precision) * value / pow(10, precision);
}

T positiveOrZero(T)(T x) if (isIntegral!(T))
{
    return x < 0 ? 0 : x;
}

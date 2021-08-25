/**
 * Authors: initkfs
 */
module os.std.math.math_strict;

import std.traits;
import os.std.errors;

// Warning! The checks are very simple and contain vulnerabilities

err addExact(T)(T a, T b, ref T sum) if (isIntegral!T)
{
    const T mustBeSum = a + b;

    static if (isUnsigned!T)
    {
        if (mustBeSum < a)
        {
            return error("Overflow occurred during unsigned addition");
        }
        else
        {
            sum = mustBeSum;
            return null;
        }
    }
    else
    {
        if ((a ^ b) >= 0 && (mustBeSum ^ b) < 0)
        {
            return error("Overflow occurred during signed addition");
        }

        sum = mustBeSum;
        return null;
    }
}

unittest
{
    import os.std.asserts : kassert;

    uint sum1;
    kassert(addExact(uint.max, 1u, sum1) !is null);

    int sum2;
    kassert(addExact(int.max, 1, sum2) !is null);

    long sum3;
    kassert(addExact(long.max - 1, 1, sum3) is null);
    kassert(sum3 == long.max);

    long sum4;
    kassert(addExact(long.max, 1, sum4) !is null);

    ulong sum5;
    kassert(addExact(ulong.max, 1u, sum5) !is null);
}

err subtractExact(T)(T a, T b, ref T sub) if (isIntegral!T)
{
    static if (isUnsigned!T)
    {
        return a < b ? error("Overflow occurred during unsigned subtraction") : (a - b);
    }
    else
    {
        const T mustBeSub = a - b;
        if ((a ^ b) < 0 && (mustBeSub ^ b) >= 0)
        {
            return error("Overflow occurred during signed subtraction");
        }

        sub = mustBeSub;
        return null;
    }

}

unittest
{
    import os.std.asserts : kassert;

    long sub1;
    kassert(subtractExact(long.min, long.min, sub1) is null);
}

//TODO unsigned
err multiplyExact(T)(T a, T b, T result) if (is(T == int) || is(T == long))
{
    if (((b > 0) && (a > T.max / b || a < T.min / b)) || ((b < -1)
            && (a > T.min / b || a < T.max / b)) || ((b == -1) && (a == T.min)))
    {
        return error("Overflow occurred during multiplicaton");
    }
    result = a * b;
    return null;
}

unittest
{
    import os.std.asserts : kassert;

    long mul1;
    kassert(multiplyExact(long.max, long.max, mul1) !is null);
}

err castExact(T, C)(T n, ref C result) if (isIntegral!T && isIntegral!C)
{
    //TODO floating point
    if (n < C.min || n > C.max)
    {
        return error("Unable to cast exact: the source number does not fit target size");
    }
    result = cast(C) n;
    return null;
}

err incrementExact(T)(T n, T result) if (isIntegral!T)
{
    if (n == T.max)
    {
        return error("Increment error: overflow");
    }
    result = n + 1;
    return null;
}

err decrementExact(T)(T n, T result) if (isIntegral!T)
{
    if (n == T.min)
    {
        return error("Decrement error: overflow");
    }
    result = n - 1;
    return null;
}

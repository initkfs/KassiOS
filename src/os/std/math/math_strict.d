/**
 * Authors: initkfs
 */
module os.std.math.math_strict;

import std.traits;
import os.std.errors;

err addExact(T)(T a, T b, ref T sum) if (is(T == int) || is(T == long))
{
    const T mustBeSum = a + b;

    if ((a ^ b) >= 0 && (mustBeSum ^ b) < 0)
    {
        return error("Overflow occurred during addition");
    }

    sum = mustBeSum;
    return null;
}

unittest
{
    import os.std.asserts : kassert;

    long sum1;
    kassert(addExact(long.max - 1, 1, sum1) is null);
    kassert(sum1 == long.max);

    long sumOverflow;
    kassert(addExact(long.max, 1, sumOverflow) !is null);
}

err subtractExact(T)(T a, T b, ref T sub) if (is(T == int) || is(T == long))
{
    const T mustBeSub = a - b;

    if ((a ^ b) < 0 && (mustBeSub ^ b) >= 0)
    {
        return error("Overflow occurred during subtraction");
    }

    sub = mustBeSub;
    return null;
}

unittest
{
    import os.std.asserts : kassert;

    long sub1;
    kassert(subtractExact(long.min, long.min, sub1) is null);
}

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

err castExact(T, C)(T n, ref C result)
        if ((is(T == long) && is(C == int)) || (is(T == int) && is(C == short))
            || (is(T == short) && is(C == byte)))
{
    if (n < C.min || n > C.max)
    {
        return error("Unable to cast long to int: the number does not fit long size");
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

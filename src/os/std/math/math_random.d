/**
 * Authors: initkfs
 */
module os.std.math.math_random;

import MathCore = os.std.math.math_core;

private
{
    __gshared ulong next = 11_111;
}

uint randUnsafe(uint minInclusive = 0, uint maxInclusive = 0) @nogc
{
    next = next * 1_103_515_245 + 12_345;
    uint result = cast(uint)(next / 65_536) % 32_768;

    if (minInclusive == 0 && maxInclusive == 0)
    {
        return result;
    }

    if (minInclusive > maxInclusive)
    {
        return result;
    }

    //TODO check bugs after deleting math intervals
    const uint inIntervalResult = MathCore.clamp(result, minInclusive, maxInclusive);
    return inIntervalResult;
}

void srandUnsafe(uint seed) @nogc
{
    next = cast(uint) seed % 32768;
}

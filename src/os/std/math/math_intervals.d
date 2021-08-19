/**
 * Authors: initkfs
 */
module os.std.math.math_intervals;


//[min, max]
@safe pure T toClosedInterval(T)(T value, T minExclusive, T maxExclusive)
        if (__traits(isIntegral, T) || __traits(isUnsigned, T))
{
    const T result = value % (maxExclusive - minExclusive + 1) + minExclusive;
    return result;
}

//(min, max]
@safe pure T toRightClosedInterval(T)(T value, T minExclusive, T maxInclusive)
        if (__traits(isIntegral, T) || __traits(isUnsigned, T))
{
    const T result = value % (maxInclusive - minExclusive) + minExclusive + 1;
    return result;
}

//[min, max)
@safe pure T toLeftClosedInterval(T)(T value, T minInclusive, T maxExclusive)
        if (__traits(isIntegral, T) || __traits(isUnsigned, T))
{
    const T result = value % (maxExclusive - minInclusive) + minInclusive;
    return result;
}

//(min, max)
@safe pure T toOpenInterval(T)(T value, T minExclusive, T maxExclusive)
        if (__traits(isIntegral, T) || __traits(isUnsigned, T))
{
    const T result = value % (maxExclusive - minExclusive - 1) + minExclusive + 1;
    return result;
}
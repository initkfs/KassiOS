/**
 * Authors: initkfs
 */
module os.std.text.strings;

import std.traits;

const string FORMAT_ERROR = "_formaterror_";

private
{
    alias Allocator = os.core.mem.allocator;
}

bool isEqualz(const char* s1, const char* s2)
{
    return isEquals(toString(s1), toString(s2));
}

bool isEquals(const string s1, const string s2)
{
    if (s1 is null || s2 is null || (s1.length != s2.length))
    {
        return false;
    }

    if (s1.length == 0 && s2.length == 0)
    {
        return true;
    }

    for (int i = 0; i < s1.length; i++)
    {
        const char char1 = s1[i];
        const char char2 = s2[i];
        if (char1 != char2)
        {
            return false;
        }
    }

    return true;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals("", ""));
    kassert(isEquals(" ", " "));
    kassert(!isEquals("", " "));
    kassert(!isEquals(" ", ""));
    kassert(!isEquals(null, ""));
    kassert(!isEquals("", null));
    kassert(!isEquals(null, null));

    kassert(isEquals("a", "a"));
    kassert(isEquals("foo bar", "foo bar"));
    kassert(!isEquals("a", "A"));

    const char[1] s1 = ['a'];
    const char[1] s2 = ['a'];
    kassert(isEquals(cast(string) s1, cast(string) s2));
}

size_t strlength(const char* str)
{
    if (!str)
    {
        return 0;
    }
    char* ptr = cast(char*) str;
    size_t length;
    while (*ptr && *ptr != char.init)
    {
        length++;
        ptr++;
    }

    return length;
}

bool isEmpty(const string str)
{
    return !str || str.length == 0;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEmpty(null));
    kassert(isEmpty(""));
    kassert(!isEmpty(" "));
    kassert(!isEmpty("a"));
}

unittest
{
    import os.std.asserts : kassert;

    kassert(strlength(null) == 0);
    kassert(strlength(cast(char*) "") == 0);
    kassert(strlength(cast(char*) " ") == 1);
    kassert(strlength(cast(char*) "a") == 1);
    kassert(strlength(cast(char*) "aaa") == 3);
    kassert(strlength(cast(char*) "a b c") == 5);
}

string toString(const char* str)
{
    return cast(string) str[0 .. strlength(str)];
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(toString(cast(char*) ""), ""));
    kassert(isEquals(toString(cast(char*) " "), " "));
    kassert(isEquals(toString(cast(char*) "foo bar"), "foo bar"));
}

char* toStringz(string str)
{
    const size = str.length + 1;
    auto buffPtr = Allocator.alloc(size);
    auto buff = cast(ubyte*) buffPtr;
    size_t index;
    foreach (ch; str)
    {
        Allocator.set(buff, ch, buffPtr, index);
        index++;
    }
    Allocator.set(buff, char.init, buffPtr, index);
    return cast(char*) buff[0 .. size];
}

unittest
{
    import os.std.asserts : kassert;

    char* s = toStringz("foo bar ");
    kassert(isEquals(toString(s), "foo bar "));
    Allocator.free(s);
}

/*
* https://stackoverflow.com/questions/18858115/c-long-long-to-char-conversion-function-in-embedded-system
*/
char* toString(const long longValue, const int base = 10)
{
    if (base < 2 || base > 16)
    {
        return toStringz("");
    }

    if (longValue == 0)
    {
        return toStringz("0");
    }

    enum size = 64;
    auto ptr = Allocator.alloc(size);
    //TODO ineffective with toStringz, but this buffer may contain garbage
    scope (exit)
    {
        Allocator.free(ptr);
    }

    char* buff = cast(char*) ptr;
    immutable char[16] alphabet = "0123456789ABCDEF";

    long val = longValue;

    int i = size - 2;
    const isNegative = (val < 0);
    if (isNegative)
    {
        val = -val;
    }

    for (; val && i; --i, val /= base)
    {
        immutable digitBaseRemainder = val % base;
        immutable letter = alphabet[digitBaseRemainder];
        Allocator.set(buff, letter, ptr, i);
    }

    if (isNegative)
    {
        auto negCharIndex = i--;
        Allocator.set(buff, '-', ptr, negCharIndex);
    }

    string result = cast(string) buff[(i + 1) .. (size - 1)];
    return toStringz(result);
}

unittest
{
    import os.std.asserts : kassert;

    auto s1 = toString(1, 0);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s1);

    auto s2 = toString(1, 1);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s2);

    auto s3 = toString(1, 17);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s3);

    //Decimal
    auto sd = toString(0, 10);
    kassert(isEquals(toString(sd), "0"));
    Allocator.free(sd);

    auto sd1 = toString(1, 10);
    kassert(isEquals(toString(sd1), "1"));
    Allocator.free(sd1);

    auto sdneg1 = toString(-1, 10);
    kassert(isEquals(toString(sdneg1), "-1"));
    Allocator.free(sdneg1);

    auto sd101 = toString(101, 10);
    kassert(isEquals(toString(sd101), "101"));
    Allocator.free(sd101);

    auto sd101neg = toString(-101, 10);
    kassert(isEquals(toString(sd101neg), "-101"));
    Allocator.free(sd101neg);

    auto sd100x = toString(10_000_000, 10);
    kassert(isEquals(toString(sd100x), "10000000"));
    Allocator.free(sd100x);

    auto sd64x = toString(648_356, 10);
    kassert(isEquals(toString(sd64x), "648356"));
    Allocator.free(sd64x);

    auto sdmax = toString(long.max, 10);
    kassert(isEquals(toString(sdmax), "9223372036854775807"));
    Allocator.free(sdmax);

    auto sdmaxNeg = toString(-(long.min - 1), 10);
    kassert(isEquals(toString(sdmaxNeg), "-9223372036854775807"));
    Allocator.free(sdmaxNeg);

    //Bin
    auto binZero = toString(0, 2);
    kassert(isEquals(toString(binZero), "0"));
    Allocator.free(binZero);

    auto binOne = toString(1, 2);
    kassert(isEquals(toString(binOne), "1"));
    Allocator.free(binOne);

    auto bin2 = toString(2, 2);
    kassert(isEquals(toString(bin2), "10"));
    Allocator.free(bin2);

    auto bin10 = toString(10, 2);
    kassert(isEquals(toString(bin10), "1010"));
    Allocator.free(bin10);

    auto bin10neg = toString(-10, 2);
    kassert(isEquals(toString(bin10neg), "-1010"));
    Allocator.free(bin10neg);

    auto bin64x = toString(648356, 2);
    kassert(isEquals(toString(bin64x), "10011110010010100100"));
    Allocator.free(bin64x);

    //Hex
    auto hZero = toString(0, 16);
    kassert(isEquals(toString(hZero), "0"));
    Allocator.free(hZero);

    auto hOne = toString(1, 16);
    kassert(isEquals(toString(hOne), "1"));
    Allocator.free(hOne);

    auto hOneNeg = toString(-1, 16);
    kassert(isEquals(toString(hOneNeg), "-1"));
    Allocator.free(hOneNeg);

    auto h10 = toString(10, 16);
    kassert(isEquals(toString(h10), "A"));
    Allocator.free(h10);

    auto h4573 = toString(4573, 16);
    kassert(isEquals(toString(h4573), "11DD"));
    Allocator.free(h4573);

    auto h0x7f = toString(0x7FFFFFFFFFFFFFFF, 16);
    kassert(isEquals(toString(h0x7f), "7FFFFFFFFFFFFFFF"));
    Allocator.free(h0x7f);
}

//TODO 1e-9 -> :e-10
// https://stackoverflow.com/questions/2302969/convert-a-float-to-a-string
char* toString(const double x, const size_t maxDigitsAfterPoint = 0,
        const double precision = 0.00000000000000001, const char sep = '.')
{
    import os.std.math.math_core : isNaN, isPositiveInf, isNegativeInf, log10, pow, floor, abs;

    if (isNaN(x))
    {
        return toStringz("NaN");
    }

    if (isPositiveInf(x))
    {
        return toStringz("+Infinity");
    }

    if (isNegativeInf(x))
    {
        return toStringz("-Infinity");
    }

    if (x == 0)
    {
        return toStringz("0.0");
    }

    double value = x;
    const bool isNeg = value < 0;
    if (isNeg)
    {
        value = abs(value);
    }

    enum maxDigits = 80 + 1;
    auto bufferSize = maxDigits;
    if (isNeg)
    {
        bufferSize++;
    }

    auto bufferPtr = Allocator.alloc(bufferSize);
    char* buffer = cast(char*) bufferPtr;

    int rankPos = cast(int) log10(value);
    int bufferIndex;
    if (isNeg)
    {
        Allocator.set(buffer, '-', bufferPtr, bufferIndex);
        bufferIndex++;
    }

    //TODO unsafe comparison
    size_t separatorIndex;
    while (value > (0 + precision) && bufferIndex < maxDigits)
    {
        const rankWeight = pow(10.0, rankPos);
        const digitIndex = cast(int) floor(value / rankWeight);
        value -= (digitIndex * rankWeight);
        const ch = cast(char)('0' + digitIndex);
        Allocator.set(buffer, ch, bufferPtr, bufferIndex);

        if (rankPos == 0)
        {
            separatorIndex = ++bufferIndex;
            Allocator.set(buffer, sep, bufferPtr, separatorIndex);
            if (value < (0 + precision))
            {
                auto zeroIndex = ++bufferIndex;
                Allocator.set(buffer, '0', bufferPtr, zeroIndex);
            }
        }

        rankPos--;
        bufferIndex++;
    }
    size_t indexExlude = bufferIndex;
    if (maxDigitsAfterPoint != 0)
    {
        const newIndex = separatorIndex + maxDigitsAfterPoint + 1;
        if (newIndex < bufferIndex)
        {
            indexExlude = newIndex;
        }
    }
    Allocator.set(buffer, char.init, bufferPtr, indexExlude++);
    auto result = cast(char*) buffer[0 .. indexExlude];
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    auto zeroPtr = toString(0.0);
    kassert(isEqualz(zeroPtr, "0.0"));
    Allocator.free(zeroPtr);

    auto infPtr = toString(double.infinity);
    kassert(isEqualz(infPtr, "+Infinity"));
    Allocator.free(infPtr);

    auto infNegPtr = toString(-double.infinity);
    kassert(isEqualz(infNegPtr, "-Infinity"));
    Allocator.free(infNegPtr);

    auto nanPtr = toString(double.nan);
    kassert(isEqualz(nanPtr, "NaN"));
    Allocator.free(nanPtr);

    auto nanNegPtr = toString(-double.nan);
    kassert(isEqualz(nanNegPtr, "NaN"));
    Allocator.free(nanNegPtr);

    auto onePtr = toString(1.0);
    kassert(isEqualz(onePtr, "1.0"));
    Allocator.free(onePtr);

    auto oneNegPtr = toString(-1.0);
    kassert(isEqualz(oneNegPtr, "-1.0"));
    Allocator.free(oneNegPtr);

    auto d1 = toString(0.02);
    kassert(isEqualz(d1, "0.01999999999999999"));
    Allocator.free(d1);

    auto d2 = toString(3.56);
    kassert(isEqualz(d2, "3.56000000000000004"));
    Allocator.free(d2);

    auto d3 = toString(-4.12);
    kassert(isEqualz(d3, "-4.12000000000000009"));
    Allocator.free(d3);
}

string reverse(const string s)
{
    if (s is null)
    {
        return "";
    }
    if (s.length < 2)
    {
        return s;
    }
    auto chars = cast(char[]) s;
    for (auto i = 0, j = chars.length - 1; i < j; i++, j--)
    {
        const char c = chars[i];
        chars[i] = chars[j];
        chars[j] = c;
    }
    return cast(string) chars;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(reverse(null), ""));
    kassert(isEquals(reverse(""), ""));
    kassert(isEquals(reverse(" "), " "));
    kassert(isEquals(reverse("a"), "a"));
    kassert(isEquals(reverse("ab"), "ba"));
    kassert(isEquals(reverse("foobar"), "raboof"));
}

long indexOf(const string str, const string pattern)
{
    enum notFoundResult = -1;
    if (!str || !pattern)
    {
        return notFoundResult;
    }

    const patternLength = pattern.length;
    const strLength = str.length;

    if (strLength == 0 || patternLength == 0 || patternLength > strLength)
    {
        return notFoundResult;
    }

    size_t i = 0;
    while ((i + patternLength <= strLength))
    {
        size_t j = 0;
        while (str[i + j] == pattern[j])
        {
            j++;
            if (j >= patternLength)
            {
                return i;
            }
        }
        i++;
    }
    return notFoundResult;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(indexOf(null, "foo") == -1);
    kassert(indexOf("foo", null) == -1);
    kassert(indexOf("", "") == -1);
    kassert(indexOf(" ", "") == -1);
    kassert(indexOf("", " ") == -1);

    kassert(indexOf("a", "a") == 0);
    kassert(indexOf("a", "A") == -1);
    kassert(indexOf("hello", "hel") == 0);
    kassert(indexOf("hello", "lo") == 3);
    kassert(indexOf("aaaab", "aaab") == 1);
    kassert(indexOf("AAAAB", "AAAB") == 1);
}

char* format(T)(const string pattern, const T[] args, const char placeholder = '%')
{
    import os.std.container.array_list;

    alias Collections = os.std.container.collections;
    //TODO very inaccurate buffer size
    size_t argsSize = args.sizeof;
    static if (is(T == string))
    {
        argsSize = 0;
        foreach (str; args)
        {
            argsSize += str.length;
        }
    }
    auto buffer = ArrayList!char(pattern.length + argsSize);
    scope (exit)
    {
        buffer.free;
    }

    size_t placeholderIndex;
    bool isPlaceholderParse;

    bool isZeroPadParse;

    //TODO check placeholder count, etc
    for (auto i = 0; i < pattern.length; i++)
    {
        auto patternChar = pattern[i];
        if (patternChar == placeholder)
        {
            isPlaceholderParse = true;
            continue;
        }

        if (isPlaceholderParse)
        {
            if (args.length == 0 || placeholderIndex >= args.length)
            {
                return toStringz(FORMAT_ERROR);
            }

            if (patternChar == '0')
            {
                isZeroPadParse = true;
                continue;
            }

            T formatArg = args[placeholderIndex];
            placeholderIndex++;

            switch (patternChar)
            {
            case 'd':
            case 'l':
                {
                    static if (isIntegral!(typeof(formatArg)))
                    {
                        const longValue = cast(long) formatArg;
                        if (isZeroPadParse)
                        {
                            if (longValue < 10)
                            {
                                buffer.push('0');
                            }
                            isZeroPadParse = false;
                        }

                        char* longStr = toString(longValue, 10);
                        Collections.append(buffer, longStr);
                        Allocator.free(longStr);
                    }
                    break;
                }
            case 'x':
                {
                    static if (isIntegral!(typeof(formatArg)))
                    {
                        buffer.push('0');
                        buffer.push('x');
                        char* hexStr = toString(cast(long) formatArg, 16);
                        Collections.append(buffer, hexStr);
                        Allocator.free(hexStr);
                    }
                    break;
                }
            case 'X':
                {
                    static if (isIntegral!(typeof(formatArg)))
                    {
                        //TODO duplicate
                        char* hexStr = toString(cast(long) formatArg, 16);
                        Collections.append(buffer, hexStr);
                        Allocator.free(hexStr);
                    }
                    break;
                }
            case 'b':
                {
                    static if (isIntegral!(typeof(formatArg)))
                    {
                        buffer.push('0');
                        buffer.push('b');
                        char* binStr = toString(cast(long) formatArg, 2);
                        Collections.append(buffer, binStr);
                        Allocator.free(binStr);
                    }
                    break;
                }
            case 's':
                {
                    static if (is(typeof(formatArg) == string))
                    {
                        Collections.append(buffer, formatArg);
                    }
                    break;
                }
            case 'f':
                {
                    static if (isFloatingPoint!(typeof(formatArg)))
                    {
                        //TODO real?
                        double value = cast(double) formatArg;
                        char* doublePtr = toString(value);
                        Collections.append(buffer, doublePtr);
                        Allocator.free(doublePtr);
                    }
                    break;
                }
            default:
                {

                }
            }

            isPlaceholderParse = false;
            continue;
        }

        buffer.push(patternChar);
    }

    string result = cast(string)(cast(ubyte*) buffer.ptr)[0 .. (buffer.length)];
    return toStringz(result);
}

unittest
{
    import os.std.asserts : kassert;

    const integralPattern = "hello %d world %l";
    ubyte[2] longArgs = [5, 10];
    char* intRes = format(integralPattern, longArgs);
    kassert(isEquals(toString(intRes), "hello 5 world 10"));
    Allocator.free(intRes);

    ubyte[1] hexArgs = [10];
    char* hexRes = format("foo %x", hexArgs);
    kassert(isEquals(toString(hexRes), "foo 0xA"));
    Allocator.free(hexRes);

    ubyte[1] hexShortArgs = [10];
    char* hexShortRes = format("foo %X", hexShortArgs);
    kassert(isEquals(toString(hexShortRes), "foo A"));
    Allocator.free(hexShortRes);

    ubyte[1] binArgs = [10];
    char* binRes = format("%b foo", binArgs);
    kassert(isEquals(toString(binRes), "0b1010 foo"));
    Allocator.free(binRes);

    string[2] strArgs = ["world", "hello"];
    char* strRes = format("%s %s", strArgs);
    kassert(isEquals(toString(strRes), "world hello"));
    Allocator.free(strRes);

    float[1] floatArgs = [4.5];
    char* flRes = format(" foo %f bar ", floatArgs);
    kassert(isEquals(toString(flRes), " foo 4.5 bar "));
    Allocator.free(flRes);
}

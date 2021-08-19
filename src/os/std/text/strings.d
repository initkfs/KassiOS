/**
 * Authors: initkfs
 */
module os.std.text.strings;

import std.traits;

private
{
    alias Allocator = os.core.mem.allocator;
}

bool isEqual(const string s1, const string s2)
{
    if (s1 is null || s2 is null)
    {
        return false;
    }

    if (s1.length != s2.length)
    {
        return false;
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

    kassert(isEqual("", ""));
    kassert(isEqual(" ", " "));
    kassert(!isEqual("", " "));
    kassert(!isEqual(" ", ""));
    kassert(!isEqual(null, ""));
    kassert(!isEqual("", null));
    kassert(!isEqual(null, null));

    kassert(isEqual("a", "a"));
    kassert(isEqual("foo bar", "foo bar"));
    kassert(!isEqual("a", "A"));

    const char[1] s1 = ['a'];
    const char[1] s2 = ['a'];
    kassert(isEqual(cast(string) s1, cast(string) s2));
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

    kassert(isEqual(toString(cast(char*) ""), ""));
    kassert(isEqual(toString(cast(char*) " "), " "));
    kassert(isEqual(toString(cast(char*) "foo bar"), "foo bar"));
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
    kassert(isEqual(toString(s), "foo bar "));
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
    kassert(isEqual(toString(s1), ""));
    Allocator.free(s1);

    auto s2 = toString(1, 1);
    kassert(isEqual(toString(s1), ""));
    Allocator.free(s2);

    auto s3 = toString(1, 17);
    kassert(isEqual(toString(s1), ""));
    Allocator.free(s3);

    //Decimal
    auto sd = toString(0, 10);
    kassert(isEqual(toString(sd), "0"));
    Allocator.free(sd);

    auto sd1 = toString(1, 10);
    kassert(isEqual(toString(sd1), "1"));
    Allocator.free(sd1);

    auto sdneg1 = toString(-1, 10);
    kassert(isEqual(toString(sdneg1), "-1"));
    Allocator.free(sdneg1);

    auto sd101 = toString(101, 10);
    kassert(isEqual(toString(sd101), "101"));
    Allocator.free(sd101);

    auto sd101neg = toString(-101, 10);
    kassert(isEqual(toString(sd101neg), "-101"));
    Allocator.free(sd101neg);

    auto sd100x = toString(10_000_000, 10);
    kassert(isEqual(toString(sd100x), "10000000"));
    Allocator.free(sd100x);

    auto sd64x = toString(648_356, 10);
    kassert(isEqual(toString(sd64x), "648356"));
    Allocator.free(sd64x);

    auto sdmax = toString(long.max, 10);
    kassert(isEqual(toString(sdmax), "9223372036854775807"));
    Allocator.free(sdmax);

    auto sdmaxNeg = toString(-(long.min - 1), 10);
    kassert(isEqual(toString(sdmaxNeg), "-9223372036854775807"));
    Allocator.free(sdmaxNeg);

    //Bin
    auto binZero = toString(0, 2);
    kassert(isEqual(toString(binZero), "0"));
    Allocator.free(binZero);

    auto binOne = toString(1, 2);
    kassert(isEqual(toString(binOne), "1"));
    Allocator.free(binOne);

    auto bin2 = toString(2, 2);
    kassert(isEqual(toString(bin2), "10"));
    Allocator.free(bin2);

    auto bin10 = toString(10, 2);
    kassert(isEqual(toString(bin10), "1010"));
    Allocator.free(bin10);

    auto bin10neg = toString(-10, 2);
    kassert(isEqual(toString(bin10neg), "-1010"));
    Allocator.free(bin10neg);

    auto bin64x = toString(648356, 2);
    kassert(isEqual(toString(bin64x), "10011110010010100100"));
    Allocator.free(bin64x);

    //Hex
    auto hZero = toString(0, 16);
    kassert(isEqual(toString(hZero), "0"));
    Allocator.free(hZero);

    auto hOne = toString(1, 16);
    kassert(isEqual(toString(hOne), "1"));
    Allocator.free(hOne);

    auto hOneNeg = toString(-1, 16);
    kassert(isEqual(toString(hOneNeg), "-1"));
    Allocator.free(hOneNeg);

    auto h10 = toString(10, 16);
    kassert(isEqual(toString(h10), "A"));
    Allocator.free(h10);

    auto h4573 = toString(4573, 16);
    kassert(isEqual(toString(h4573), "11DD"));
    Allocator.free(h4573);

    auto h0x7f = toString(0x7FFFFFFFFFFFFFFF, 16);
    kassert(isEqual(toString(h0x7f), "7FFFFFFFFFFFFFFF"));
    Allocator.free(h0x7f);
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

    kassert(isEqual(reverse(null), ""));
    kassert(isEqual(reverse(""), ""));
    kassert(isEqual(reverse(" "), " "));
    kassert(isEqual(reverse("a"), "a"));
    kassert(isEqual(reverse("ab"), "ba"));
    kassert(isEqual(reverse("foobar"), "raboof"));
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

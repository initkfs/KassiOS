/**
 * Authors: initkfs
 */
module os.std.text.strings;

import std.traits;

const string FORMAT_ERROR = "_formaterror_";
const char NULL_BYTE = '\0';
const string EMPTY = "";
enum NOT_FOUND = -1;

import Allocator = os.core.mem.allocator;
import Ascii = os.std.text.ascii;
import MathCore = os.std.math.math_core;
import MathStrict = os.std.math.math_strict;

bool isEqualz(const char* s1, const char* s2)
{
    return isEquals(toString(s1), toString(s2));
}

bool isEqualsIgnoreCase(const string s1, const string s2)
{
    auto s1ptr = toLower(s1);
    auto s2ptr = toLower(s2);
    scope (exit)
    {
        Allocator.free(s1ptr, s2ptr);
    }
    return isEqualz(s1ptr, s2ptr);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEqualsIgnoreCase("BAZ", "baz"));
    kassert(isEqualsIgnoreCase("foo", "Foo"));
    kassert(!isEqualsIgnoreCase("foo", "f0o"));
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

size_t lengthz(const char* str)
{
    if (!str)
    {
        return 0;
    }

    char* ptr = cast(char*) str;
    size_t length;
    while (*ptr && *ptr != NULL_BYTE)
    {
        length++;
        ptr++;
    }

    return length;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(lengthz(null) == 0);
    kassert(lengthz("".ptr) == 0);
    kassert(lengthz(" ".ptr) == 1);
    kassert(lengthz("a".ptr) == 1);
    kassert(lengthz("aaa".ptr) == 3);
    kassert(lengthz("a b c".ptr) == 5);
}

char* transform(string s, char delegate(char) onChar)
{
    if (s.length == 0)
    {
        return toStringz(EMPTY);
    }

    auto buffPtr = Allocator.alloc(s.length + 1);
    auto buff = cast(char*) buffPtr;
    foreach (i, ch; s)
    {
        const char newChar = onChar(ch);
        Allocator.set(buff, newChar, buffPtr, i);
    }

    Allocator.set(buff, NULL_BYTE, buffPtr, s.length);
    return buff;
}

char* toLower(string s)
{
    return transform(s, (char ch) {
        if (ch >= 'A' && ch <= 'Z')
        {
            return cast(char)(ch + 32);
        }
        return ch;
    });
}

unittest
{
    import os.std.asserts : kassert;

    auto s1 = toLower("foobar");
    kassert(isEqualz(s1, "foobar".ptr));
    Allocator.free(s1);

    auto s2 = toLower("FooBar");
    kassert(isEqualz(s2, "foobar".ptr));
    Allocator.free(s2);

    auto s3 = toLower("FOOBAR");
    kassert(isEqualz(s3, "foobar".ptr));
    Allocator.free(s3);
}

char* toUpper(string s)
{
    return transform(s, (char ch) {
        if (ch >= 'a' && ch <= 'z')
        {
            return cast(char)(ch - 32);
        }
        return ch;
    });
}

unittest
{
    import os.std.asserts : kassert;

    auto s1 = toUpper("foobar");
    kassert(isEqualz(s1, "FOOBAR".ptr));
    Allocator.free(s1);

    auto s2 = toUpper("FooBar");
    kassert(isEqualz(s2, "FOOBAR".ptr));
    Allocator.free(s2);

    auto s3 = toUpper("FOOBAR");
    kassert(isEqualz(s3, "FOOBAR".ptr));
    Allocator.free(s3);
}

bool isEmptyz(const char* str)
{
    return !str || lengthz(str) == 0;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEmptyz("".ptr));
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

bool isBlank(const string str)
{
    if (!str || str.length == 0)
    {
        return true;
    }

    foreach (ch; str)
    {
        if (!Ascii.isSpace(ch))
        {
            return false;
        }
    }

    return true;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isBlank(null));
    kassert(isBlank(""));
    kassert(isBlank(" "));
    kassert(isBlank(" \n \t  \t "));
    kassert(!isBlank("  a  "));
}

string toString(const char* str)
{
    return cast(string) str[0 .. lengthz(str)];
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(toString("".ptr), ""));
    kassert(isEquals(toString(" ".ptr), " "));
    kassert(isEquals(toString("foo bar".ptr), "foo bar"));
}

char* toStringzBuf(string str, char* buffer)
{
    size_t size;
    const incErr = MathStrict.incrementExact(str.length, size);
    if (incErr)
    {
        buffer[0] = NULL_BYTE;
        return buffer;
    }

    size_t index;
    foreach (ch; str)
    {
        buffer[index] = ch;
        index++;
    }

    buffer[index] = NULL_BYTE;
    return buffer;
}

char* toStringz(string str)
{
    size_t size;
    const incErr = MathStrict.incrementExact(str.length, size);
    if (incErr)
    {
        return toStringz(EMPTY);
    }

    auto buffPtr = Allocator.alloc(size);
    auto buff = cast(ubyte*) buffPtr;
    size_t index;
    foreach (ch; str)
    {
        Allocator.set(buff, ch, buffPtr, index);
        index++;
    }

    Allocator.set(buff, NULL_BYTE, buffPtr, index);

    return cast(char*) buff;
}

unittest
{
    import os.std.asserts : kassert;

    char* s = toStringz("foo bar ");
    kassert(isEquals(toString(s), "foo bar "));
    Allocator.free(s);
}

string toString(const long longValue, char* buff, int buffSize, const int base = 10)
{
    if (base < 2 || base > 16)
    {
        return EMPTY;
    }

    if (longValue == 0)
    {
        return "0";
    }

    immutable char[16] alphabet = "0123456789ABCDEF";

    long val = longValue;

    int i = buffSize - 2;
    const isNegative = (val < 0);
    if (isNegative)
    {
        val = -val;
    }

    for (; val && i; --i, val /= base)
    {
        immutable digitBaseRemainder = val % base;
        immutable letter = alphabet[digitBaseRemainder];
        buff[i] = letter;
    }

    if (isNegative)
    {
        auto negCharIndex = i--;
        buff[negCharIndex] = '-';
    }

    string result = cast(string) buff[(i + 1) .. (buffSize - 1)];
    //TODO check i < buffer length, remove unnecessary copying into memory
    return result;
}

/*
* https://stackoverflow.com/questions/18858115/c-long-long-to-char-conversion-function-in-embedded-system
*/
char* toStringz(const long longValue, const int base = 10)
{
    enum buffSize = 64;
    auto buff = cast(char*) Allocator.alloc(buffSize);
    scope(exit){
        Allocator.free(buff);
    }
    //TODO remove buffer and null-byte
    string result = toString(longValue, buff, buffSize, base);
    return toStringz(result);
}

unittest
{
    import os.std.asserts : kassert;

    auto s1 = toStringz(1, 0);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s1);

    auto s2 = toStringz(1, 1);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s2);

    auto s3 = toStringz(1, 17);
    kassert(isEquals(toString(s1), ""));
    Allocator.free(s3);

    //Decimal
    auto sd = toStringz(0, 10);
    kassert(isEquals(toString(sd), "0"));
    Allocator.free(sd);

    auto sd1 = toStringz(1, 10);
    kassert(isEquals(toString(sd1), "1"));
    Allocator.free(sd1);

    auto sdneg1 = toStringz(-1, 10);
    kassert(isEquals(toString(sdneg1), "-1"));
    Allocator.free(sdneg1);

    auto sd101 = toStringz(101, 10);
    kassert(isEquals(toString(sd101), "101"));
    Allocator.free(sd101);

    auto sd101neg = toStringz(-101, 10);
    kassert(isEquals(toString(sd101neg), "-101"));
    Allocator.free(sd101neg);

    auto sd100x = toStringz(10_000_000, 10);
    kassert(isEquals(toString(sd100x), "10000000"));
    Allocator.free(sd100x);

    auto sd64x = toStringz(648_356, 10);
    kassert(isEquals(toString(sd64x), "648356"));
    Allocator.free(sd64x);

    auto sdmax = toStringz(long.max, 10);
    kassert(isEquals(toString(sdmax), "9223372036854775807"));
    Allocator.free(sdmax);

    auto sdmaxNeg = toStringz(-(long.min - 1), 10);
    kassert(isEquals(toString(sdmaxNeg), "-9223372036854775807"));
    Allocator.free(sdmaxNeg);

    //Bin
    auto binZero = toStringz(0, 2);
    kassert(isEquals(toString(binZero), "0"));
    Allocator.free(binZero);

    auto binOne = toStringz(1, 2);
    kassert(isEquals(toString(binOne), "1"));
    Allocator.free(binOne);

    auto bin2 = toStringz(2, 2);
    kassert(isEquals(toString(bin2), "10"));
    Allocator.free(bin2);

    auto bin10 = toStringz(10, 2);
    kassert(isEquals(toString(bin10), "1010"));
    Allocator.free(bin10);

    auto bin10neg = toStringz(-10, 2);
    kassert(isEquals(toString(bin10neg), "-1010"));
    Allocator.free(bin10neg);

    auto bin64x = toStringz(648356, 2);
    kassert(isEquals(toString(bin64x), "10011110010010100100"));
    Allocator.free(bin64x);

    //Hex
    auto hZero = toStringz(0, 16);
    kassert(isEquals(toString(hZero), "0"));
    Allocator.free(hZero);

    auto hOne = toStringz(1, 16);
    kassert(isEquals(toString(hOne), "1"));
    Allocator.free(hOne);

    auto hOneNeg = toStringz(-1, 16);
    kassert(isEquals(toString(hOneNeg), "-1"));
    Allocator.free(hOneNeg);

    auto h10 = toStringz(10, 16);
    kassert(isEquals(toString(h10), "A"));
    Allocator.free(h10);

    auto h4573 = toStringz(4573, 16);
    kassert(isEquals(toString(h4573), "11DD"));
    Allocator.free(h4573);

    auto h0x7f = toStringz(0x7FFFFFFFFFFFFFFF, 16);
    kassert(isEquals(toString(h0x7f), "7FFFFFFFFFFFFFFF"));
    Allocator.free(h0x7f);
}

//TODO 1e-9 -> :e-10
// https://stackoverflow.com/questions/2302969/convert-a-float-to-a-string
char* toStringz(const double x, const size_t maxDigitsAfterPoint = 0,
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
    Allocator.set(buffer, NULL_BYTE, bufferPtr, indexExlude++);
    //auto result = cast(char*) buffer[0 .. indexExlude];
    return buffer;
}

unittest
{
    import os.std.asserts : kassert;

    auto zeroPtr = toStringz(0.0);
    kassert(isEqualz(zeroPtr, "0.0"));
    Allocator.free(zeroPtr);

    auto infPtr = toStringz(double.infinity);
    kassert(isEqualz(infPtr, "+Infinity"));
    Allocator.free(infPtr);

    auto infNegPtr = toStringz(-double.infinity);
    kassert(isEqualz(infNegPtr, "-Infinity"));
    Allocator.free(infNegPtr);

    auto nanPtr = toStringz(double.nan);
    kassert(isEqualz(nanPtr, "NaN"));
    Allocator.free(nanPtr);

    auto nanNegPtr = toStringz(-double.nan);
    kassert(isEqualz(nanNegPtr, "NaN"));
    Allocator.free(nanNegPtr);

    auto onePtr = toStringz(1.0);
    kassert(isEqualz(onePtr, "1.0"));
    Allocator.free(onePtr);

    auto oneNegPtr = toStringz(-1.0);
    kassert(isEqualz(oneNegPtr, "-1.0"));
    Allocator.free(oneNegPtr);

    auto d1 = toStringz(0.02);
    kassert(isEqualz(d1, "0.01999999999999999"));
    Allocator.free(d1);

    auto d2 = toStringz(3.56);
    kassert(isEqualz(d2, "3.56000000000000004"));
    Allocator.free(d2);

    auto d3 = toStringz(-4.12);
    kassert(isEqualz(d3, "-4.12000000000000009"));
    Allocator.free(d3);
}

string reverse(const string s)
{
    if (s is null)
    {
        return EMPTY;
    }
    if (s.length <= 1)
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

long lastIndexOf(const string str, const string pattern)
{
    return indexOfAny(str, pattern, true);
}

long indexOf(const string str, const string pattern)
{
    return indexOfAny(str, pattern);
}

private long indexOfAny(const string str, const string pattern,
    bool isLastIndexOf = false, size_t index = 0)
{
    if (!str || !pattern)
    {
        return NOT_FOUND;
    }

    const patternLength = pattern.length;
    const length = str.length;

    if (length == 0 || patternLength == 0 || patternLength > length)
    {
        return NOT_FOUND;
    }

    size_t i = index;
    if (isLastIndexOf)
    {
        i = index > 0 && index < str.length ? index : str.length;
    }
    //TODO overflow?
    while ((!isLastIndexOf && (i + patternLength <= length)) || (isLastIndexOf
            && (i - patternLength >= 0)))
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
        if (!isLastIndexOf)
            i++;
        else
            i--;
    }
    return NOT_FOUND;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(indexOfAny(null, "foo") == -1);
    kassert(indexOfAny("foo", null) == -1);
    kassert(indexOfAny("", "") == -1);
    kassert(indexOfAny(" ", "") == -1);
    kassert(indexOfAny("", " ") == -1);

    kassert(indexOfAny("a", "a") == 0);
    kassert(indexOfAny("a", "A") == -1);
    kassert(indexOfAny("hello", "hel") == 0);
    kassert(indexOfAny("hello", "lo") == 3);
    kassert(indexOfAny("aaaab", "aaab") == 1);
    kassert(indexOfAny("AAAAB", "AAAB") == 1);

    kassert(indexOfAny("aabaab", "aab", true) == 3);
    kassert(indexOfAny("AAAAB", "AA", true) == 2);
}

bool contains(string str, string pattern)
{
    return indexOf(str, pattern) != -1;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(contains("aabaab", "aab"));
    kassert(!contains("aabaab", "aabb"));
}

bool startsWith(string str, string pattern)
{
    return indexOf(str, pattern) == 0;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(!startsWith("foo", "fob"));
    kassert(startsWith("foo", "f"));
    kassert(startsWith("foo", "fo"));
    kassert(startsWith("foo", "foo"));
    kassert(!startsWith("foo", "fooo"));
}

bool endsWith(string str, string pattern)
{
    import os.std.math.math_strict : subtractExact;

    size_t lastIndex;
    const err = subtractExact(str.length, pattern.length, lastIndex);
    if (err)
    {
        return false;
    }
    return lastIndexOf(str, pattern) == lastIndex;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(endsWith("foo", "o"));
    kassert(endsWith("foo", "oo"));
    kassert(endsWith("foo", "foo"));
    kassert(!endsWith("foo", "fooo"));
}

char* replace(string s, string searchFor, string replaceWith)
{
    import List = os.std.container.linear_list;

    if (s.length == 0 || searchFor.length == 0 || replaceWith.length == 0)
    {
        return toStringz(EMPTY);
    }

    if (searchFor.length > s.length)
    {
        return toStringz(s);
    }

    List.LinearList* appender;
    size_t index = 0;
    size_t startIndex = 0;
    while ((index = indexOfAny(s, searchFor, false, index)) != NOT_FOUND)
    {
        if (appender is null)
        {
            appender = List.initList!char(s.length + replaceWith.length);
        }

        foreach (i; startIndex .. index)
        {
            const ch = s[i];
            List.push!char(appender, ch);
        }

        foreach (ch; replaceWith)
        {
            List.push!char(appender, ch);
        }

        index += searchFor.length;
        startIndex = index;
    }

    if (index == 0 || appender is null)
    {
        return toStringz(s);
    }

    auto rest = s[startIndex .. $];
    foreach (ch; rest)
    {
        List.push!char(appender, ch);
    }

    const string resultStr = cast(string) appender.data.ptr[0 .. appender.length];
    char* result = toStringz(resultStr);

    Allocator.free(appender);

    return result;
}

unittest
{
    import os.std.asserts : kassert;

    auto s1 = replace(" ", " ", " ");
    kassert(isEqualz(s1, " ".ptr));
    Allocator.free(s1);

    auto s2 = replace("foo", "o", "b");
    kassert(isEqualz(s2, "fbb".ptr));
    Allocator.free(s2);

    auto s3 = replace("helloworld", "hello", "nothello");
    kassert(isEqualz(s3, "nothelloworld".ptr));
    Allocator.free(s3);

    auto s4 = replace("hello %s", "%s", "world");
    kassert(isEqualz(s4, "hello world".ptr));
    Allocator.free(s4);

    auto s5 = replace("foo", "bar", "baz");
    kassert(isEqualz(s5, "foo".ptr));
    Allocator.free(s5);
}

string take(string str, long num, bool isDropChars = false)
{

    import MathCore = os.std.math.math_core;

    if (!str)
    {
        return EMPTY;
    }

    if (str.length == 0 || num == 0)
    {
        return str;
    }

    const size = MathCore.min(MathCore.abs(num), str.length);

    if (!isDropChars)
    {
        return num > 0 ? str[0 .. size] : str[($ - size) .. $];
    }

    return num > 0 ? str[size .. $] : str[0 .. $ - size];
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(take("foo", 0), "foo"));
    kassert(isEquals(take("foo", 1), "f"));
    kassert(isEquals(take("foo", 2), "fo"));
    kassert(isEquals(take("foo", 3), "foo"));
    kassert(isEquals(take("foo", 4), "foo"));
    kassert(isEquals(take("foo", 100), "foo"));

    kassert(isEquals(take("foo", -1), "o"));
    kassert(isEquals(take("foo", -2), "oo"));
    kassert(isEquals(take("foo", -3), "foo"));
    kassert(isEquals(take("foo", -4), "foo"));
    kassert(isEquals(take("foo", -100), "foo"));
}

string drop(string str, long num)
{
    return take(str, num, true);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(drop("foo", 0), "foo"));
    kassert(isEquals(drop("foo", 1), "oo"));
    kassert(isEquals(drop("foo", 2), "o"));
    kassert(isEquals(drop("foo", 3), ""));
    kassert(isEquals(drop("foo", 100), ""));

    kassert(isEquals(drop("foo", -1), "fo"));
    kassert(isEquals(drop("foo", -2), "f"));
    kassert(isEquals(drop("foo", -3), ""));
    kassert(isEquals(drop("foo", -100), ""));
}

char* repeat(string s, size_t num)
{
    if (!s || s.length == 0 || num == 0)
    {
        return toStringz(EMPTY);
    }
    const buffSize = s.length * num + 1;
    auto buffPtr = Allocator.alloc(buffSize);
    char* buff = cast(char*) buffPtr;

    foreach (i; 0 .. num)
    {
        foreach (j, ch; s)
        {
            Allocator.set(buff, ch, buffPtr, (i * s.length + j));
        }
    }

    Allocator.set(buff, NULL_BYTE, buffPtr, buffSize - 1);

    return buff;
}

unittest
{
    import os.std.asserts : kassert;

    auto foofooPtr = repeat("foo", 2);
    kassert(isEqualz(foofooPtr, "foofoo".ptr));
    Allocator.free(foofooPtr);

    auto bar5Ptr = repeat("bar", 5);
    kassert(isEqualz(bar5Ptr, "barbarbarbarbar".ptr));
    Allocator.free(bar5Ptr);
}

private char* pad(string s, size_t numberOfChars, char padChar = ' ',
    bool isLeft = true, bool isRight = true)
{
    if (numberOfChars <= s.length || s.length == 0 || (!isLeft && !isRight))
    {
        return toStringz(s);
    }

    auto buffPtr = Allocator.alloc(numberOfChars + 1);
    auto buff = cast(char*) buffPtr;

    auto charsToAdd = numberOfChars - s.length;
    auto leftBorderSize = charsToAdd;
    if (isLeft && isRight)
    {
        leftBorderSize = charsToAdd >= 2 ? charsToAdd / 2 : charsToAdd;
    }

    size_t currentCharIndex;

    if (isLeft)
    {
        foreach (i; 0 .. leftBorderSize)
        {
            Allocator.set(buff, padChar, buffPtr, currentCharIndex);
            currentCharIndex++;
        }
    }

    foreach (ch; s)
    {
        Allocator.set(buff, ch, buffPtr, currentCharIndex);
        currentCharIndex++;
    }

    if (isRight)
    {
        foreach (i; currentCharIndex .. numberOfChars)
        {
            Allocator.set(buff, padChar, buffPtr, currentCharIndex);
            currentCharIndex++;
        }
    }

    return buff;
}

char* center(string s, size_t numberOfChars, char padChar = ' ')
{
    return pad(s, numberOfChars, padChar);
}

unittest
{
    import os.std.asserts : kassert;

    auto c1 = center("foo", 2);
    kassert(isEqualz(c1, "foo".ptr));
    Allocator.free(c1);

    auto c2 = center("foo", 4, '#');
    kassert(isEqualz(c2, "#foo".ptr));
    Allocator.free(c2);

    auto c3 = center("foo", 5, '#');
    kassert(isEqualz(c3, "#foo#".ptr));
    Allocator.free(c3);

    auto c4 = center("foo", 10, '#');
    kassert(isEqualz(c4, "###foo####".ptr));
    Allocator.free(c4);
}

char* padLeft(string s, size_t numberOfChars, char padChar = ' ')
{
    return pad(s, numberOfChars, padChar, true, false);
}

unittest
{
    import os.std.asserts : kassert;

    auto c1 = padLeft("foo", 2);
    kassert(isEqualz(c1, "foo".ptr));
    Allocator.free(c1);

    auto c2 = padLeft("foo", 4, '#');
    kassert(isEqualz(c2, "#foo".ptr));
    Allocator.free(c2);

    auto c3 = padLeft("foo", 5, '#');
    kassert(isEqualz(c3, "##foo".ptr));
    Allocator.free(c3);

    auto c4 = padLeft("foo", 10, '#');
    kassert(isEqualz(c4, "#######foo".ptr));
    Allocator.free(c4);
}

char* padRight(string s, size_t numberOfChars, char padChar = ' ')
{
    return pad(s, numberOfChars, padChar, false, true);
}

unittest
{
    import os.std.asserts : kassert;

    auto c1 = padRight("foo", 2);
    kassert(isEqualz(c1, "foo".ptr));
    Allocator.free(c1);

    auto c2 = padRight("foo", 4, '#');
    kassert(isEqualz(c2, "foo#".ptr));
    Allocator.free(c2);

    auto c3 = padRight("foo", 5, '#');
    kassert(isEqualz(c3, "foo##".ptr));
    Allocator.free(c3);

    auto c4 = padRight("foo", 10, '#');
    kassert(isEqualz(c4, "foo#######".ptr));
    Allocator.free(c4);
}

string trim(string s)
{
    if (s.length == 0)
    {
        return s;
    }

    if (isBlank(s))
    {
        return EMPTY;
    }

    size_t indexLeft;
    size_t indexRight = s.length - 1;
    foreach (ch; s)
    {
        if (!Ascii.isSpace(ch))
        {
            break;
        }
        indexLeft++;
    }

    foreach_reverse (ch; s)
    {
        if (!Ascii.isSpace(ch))
        {
            break;
        }
        indexRight--;
    }

    string result = s[indexLeft .. indexRight + 1];
    return result;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isEquals(trim(" "), ""));
    kassert(isEquals(trim("  "), ""));
    kassert(isEquals(trim(" a"), "a"));
    kassert(isEquals(trim("a "), "a"));
    kassert(isEquals(trim("foobar"), "foobar"));
    kassert(isEquals(trim(" foo"), "foo"));
    kassert(isEquals(trim("foo "), "foo"));
    kassert(isEquals(trim("  foo   "), "foo"));
    kassert(isEquals(trim(" \n\tfoo \n"), "foo"));
}

int compare(string s1, string s2)
{
    const size_t length = MathCore.min(s1.length, s2.length);
    foreach (i; 0 .. length)
    {
        if (s1[i] != s2[i])
        {
            return s1[i] < s2[i] ? -1 : 1;
        }
    }
    return 0;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(compare("aa", "aa") == 0);
    kassert(compare("ab", "aa") == 1);
    kassert(compare("aa", "ab") == -1);
    kassert(compare("abaa", "aabb") == 1);
}

char* format(T)(const string pattern, const T[] args, const char placeholder = '%')
{
    import os.std.container.array_list : ArrayList;

    import Collections = os.std.container.collections;

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

                        char* longStr = toStringz(longValue, 10);
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
                        char* hexStr = toStringz(cast(long) formatArg, 16);
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
                        char* hexStr = toStringz(cast(long) formatArg, 16);
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
                        char* binStr = toStringz(cast(long) formatArg, 2);
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
                        char* doublePtr = toStringz(value);
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

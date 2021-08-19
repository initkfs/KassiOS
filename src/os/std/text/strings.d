/**
 * Authors: initkfs
 */
module os.std.text.strings;

import std.traits;

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

/**
 * Authors: initkfs
 */
module os.std.text.ascii;

enum NUL = '\0';
enum BEL = '\a';
enum BS = '\b';
enum TAB = '\t';
enum LF = '\n';
enum VT = '\v';
enum FF = '\f';
enum CR = '\r';

bool isBackspace(const char code) @safe pure
{
	return code == 8;
}

bool isDecimalDigit(const char c)
{
	return c >= '0' && c <= '9';
}

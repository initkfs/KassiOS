/**
 * Authors: initkfs
 */
module os.core.graphic.text_display;

import Ascii = os.std.text.ascii;
import Ports = os.core.io.ports;
import List = os.std.container.linear_list;
import Syslog = os.core.logger.syslog;
import Strings = os.std.text.strings;
import Math = os.std.math.math_core;

enum
{
    DISPLAY_COLUMNS = 80,
    DISPLAY_LINES = 25,
    DISPLAY_ATTRIBUTE = 7,
    DISPLAY_MAX_INDEX = DISPLAY_COLUMNS * DISPLAY_LINES * 2,
}

__gshared enum CGAColors
{
    COLOR_BLACK = 0, //00 00 00
    COLOR_BLUE = 1, //00 00 AA
    COLOR_GREEN = 0x02, //00 AA 00
    COLOR_CYAN = 3, //00 AA AA
    COLOR_RED = 4, //AA 00 00
    COLOR_PURPLE = 5, //AA 00 AA
    COLOR_BROWN = 6, //AA 55 00
    COLOR_GRAY = 7, //AA AA AA
    COLOR_DARK_GRAY = 8, //55 55 55
    COLOR_LIGHT_BLUE = 9, //55 55 FF
    COLOR_LIGHT_GREEN = 10, //55 FF 55
    COLOR_LIGHT_CYAN = 11, //55 FF FF
    COLOR_LIGHT_RED = 12, //FF 55 55
    COLOR_LIGHT_PURPLE = 13, //FF 55 FF
    COLOR_YELLOW = 14, //FF FF 55
    COLOR_WHITE = 15, //FF FF FF
    DEFAULT_TEXT_COLOR = COLOR_GRAY
}

__gshared enum CGAInfoColors
{
    COLOR_SUCCESS = CGAColors.COLOR_LIGHT_GREEN,
    COLOR_WARNING = CGAColors.COLOR_YELLOW,
    COLOR_INFO = CGAColors.COLOR_CYAN,
    COLOR_ERROR = CGAColors.COLOR_LIGHT_RED
}

private __gshared
{
    ubyte* textVideoMemoryPtr = cast(ubyte*) 0xB8000;
    bool cursorEnabled = false;

    int displayIndexX;
    int displayIndexY;

    int displayStartIndexX;
    int displayStartIndexY;

    bool textBufferEnabled = false;

    List.LinearList* textBuffer;
    TextBufferWindowStatus textBufferStatus = TextBufferWindowStatus.MIN;
    long textBufferStartIndex;
    long textBufferEndIndex;
}

private enum TextBufferWindowStatus
{
    MIN,
    SLIDING,
    MAX
}

bool isCursorEnabled() @nogc
{
    return cursorEnabled;
}

//https://wiki.osdev.org/Text_Mode_Cursor
void enableCursor(const ubyte cursorStart = 0, const ubyte cursorEnd = DISPLAY_COLUMNS) @nogc
{
    if (isCursorEnabled)
    {
        return;
    }

    Ports.outportb(0x3D4, 0x0A);

    const currStart = Ports.inport!ubyte(0x3D5);
    Ports.outportb(0x3D5, (currStart & 0xC0) | cursorStart);

    Ports.outportb(0x3D4, 0x0B);

    const currEnd = Ports.inport!ubyte(0x3D5);
    Ports.outportb(0x3D5, (currEnd & 0xE0) | cursorEnd);

    cursorEnabled = true;
}

void disableCursor() @nogc
{
    if (!isCursorEnabled)
    {
        return;
    }

    Ports.outportb(0x3D4, 0x0A);
    Ports.outportb(0x3D5, 0x20);
    cursorEnabled = false;
}

private void updateCursor() @nogc
{
    const uint pos = displayIndexY * DISPLAY_COLUMNS + displayIndexX;

    Ports.outportb(0x3D4, 0x0F);
    Ports.outportb(0x3D5, (pos & 0xFF));
    Ports.outportb(0x3D4, 0x0E);
    Ports.outportb(0x3D5, ((pos >> 8) & 0xFF));
}

private size_t updateCoordinates()
{
    if (displayIndexX > DISPLAY_COLUMNS - 1)
    {
        newLine;
    }

    //row = chars in row * 2 (char + color)
    const rowBytesCount = displayIndexY * DISPLAY_COLUMNS * 2;
    const currentColumnBytesCount = displayIndexX * 2;

    const positionByteX = rowBytesCount + currentColumnBytesCount;
    return positionByteX;
}

private void resetCoordinates() @nogc
{
    displayIndexX = displayStartIndexX;
    displayIndexY = displayStartIndexY;
}

void backspace(const size_t border = 0, const char emptyChar = ' ',
    const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    if (displayIndexX <= border)
    {
        return;
    }

    if (textBufferEnabled && textBuffer !is null && !List.isEmpty(textBuffer))
    {
        ubyte removed;
        List.pop(textBuffer, removed);
        updateTextBufferIndices;
    }

    auto isBuffer = textBufferEnabled;
    if (isBuffer)
    {
        textBufferEnabled = false;
    }

    displayIndexX--;
    writeToTextVideoMemory(updateCoordinates, emptyChar, color);
    updateCursor;

    if (isBuffer)
    {
        textBufferEnabled = true;
    }
}

void skipColumn()
{
    displayIndexX++;
    updateCoordinates;
}

void newLine()
{
    displayIndexY++;
    displayIndexX = 0;

    if (textBufferEnabled && textBuffer !is null)
    {
        if (!List.isEmpty(textBuffer))
        {
            ubyte last;
            List.last(textBuffer, last);
            if (last == Ascii.LF)
            {
                return;
            }
        }
        writeToTextBuffer(Ascii.LF);
    }
}

private void updateTextBufferIndices() @nogc
{
    if (!textBufferEnabled || textBuffer is null)
    {
        return;
    }
    const length = textBuffer.length;
    textBufferStartIndex = length == 0 ? 0 : length - 1;
    textBufferEndIndex = textBufferStartIndex;
}

private void writeToTextBuffer(ubyte value)
{
    if (!textBufferEnabled || textBuffer is null)
    {
        return;
    }

    List.push!ubyte(textBuffer, value);

    updateTextBufferIndices;
}

private long findBufferLineOffsetLeft(size_t startIndex)
{
    return findBufferLineOffset(startIndex, true);
}

private long findBufferLineOffsetRight(size_t startIndex)
{
    return findBufferLineOffset(startIndex, false);
}

private long findBufferLineOffset(size_t startIndex, bool isReverse = false)
{
    if (textBuffer is null || textBuffer.length == 0)
    {
        return 0;
    }

    long i = startIndex;
    ubyte currentValue;
    List.get!ubyte(textBuffer, i, currentValue);
    if (currentValue == Ascii.LF)
    {
        if (isReverse)
        {
            i--;
        }
        else
        {
            if (i == textBuffer.length - 1)
            {
                return 0;
            }
            i++;
        }
    }

    long pos = startIndex;
    while ((!isReverse && i < textBuffer.length) || (isReverse && i >= 0))
    {
        ubyte ch;
        List.get!ubyte(textBuffer, i, ch);
        if (ch == Ascii.LF)
        {
            pos = i;
            break;
        }
        if (isReverse)
            i--;
        else
            i++;
    }
    long offset = !isReverse ? pos - startIndex : startIndex - pos;
    if (offset < 0)
    {
        offset = -offset;
    }

    return offset;
}

void scrollToUp()
{
    if (!textBufferEnabled || textBuffer is null)
    {
        return;
    }

    if (isCursorEnabled)
    {
        disableCursor;
    }

    if (!List.isEmpty(textBuffer))
    {
        ubyte lastValue;
        List.last(textBuffer, lastValue);
        if (lastValue != Ascii.LF)
        {
            writeToTextBuffer(Ascii.LF);
        }
    }

    clearScreen(false);

    textBufferStartIndex -= findBufferLineOffsetLeft(textBufferStartIndex);
    textBufferStartIndex = Math.positiveOrZero(textBufferStartIndex);

    if (textBufferStatus == TextBufferWindowStatus.MAX)
    {
        textBufferEndIndex -= findBufferLineOffsetLeft(textBufferEndIndex);
        textBufferEndIndex = Math.positiveOrZero(textBufferEndIndex);
    }

    if (textBufferStartIndex == textBufferEndIndex)
    {
        //TODO preventing window collapse
    }

    renderTextBuffer;
}

void scrollToDown()
{
    if (!textBufferEnabled || textBuffer is null)
    {
        return;
    }

    if (textBufferStatus == TextBufferWindowStatus.MIN)
    {
        if (!cursorEnabled)
        {
            enableCursor;
        }
        return;
    }

    if (textBufferEndIndex < textBuffer.length - 1)
    {
        const offset = findBufferLineOffsetRight(textBufferEndIndex);
        textBufferEndIndex += offset;
        textBufferEndIndex = List.orMaxIndex(textBuffer, textBufferEndIndex);
    }

    textBufferStartIndex += findBufferLineOffsetRight(textBufferStartIndex);
    textBufferStartIndex = List.orMaxIndex(textBuffer, textBufferStartIndex);

    disableCursor;
    clearScreen(false);

    if (textBufferStartIndex == textBufferEndIndex)
    {
        //TODO preventing window collapse
    }

    renderTextBuffer;
}

private void renderTextBuffer(long start, long end)
{
    if (!textBufferEnabled || textBuffer is null)
    {
        return;
    }

    const startIndex = List.orMaxIndex(textBuffer, start);
    const endIndex = List.orMaxIndex(textBuffer, end);

    textBufferEnabled = false;

    size_t lineCount;
    foreach (i; startIndex .. endIndex + 1)
    {
        ubyte value;
        List.get!ubyte(textBuffer, i, value);
        if (value == Ascii.LF)
        {
            if (lineCount == 0 || i == end)
            {
                lineCount++;
                continue;
            }

            newLine;
            lineCount++;
        }
        else
        {
            printChar(value);
        }

        if (displayIndexY >= DISPLAY_LINES - 2)
        {
            textBufferStatus = TextBufferWindowStatus.MAX;
        }
        else if ((displayStartIndexY == 0 && displayIndexY == 0)
            || (displayStartIndexY > 0 && (displayIndexY - displayStartIndexY) == 1))
        {
            textBufferStatus = TextBufferWindowStatus.MIN;
        }
        else
        {
            textBufferStatus = TextBufferWindowStatus.SLIDING;
        }
    }

    textBufferEnabled = true;
}

private void renderTextBuffer()
{
    renderTextBuffer(textBufferStartIndex, textBufferEndIndex);
}

private void writeToTextVideoMemory(size_t position, const ubyte value,
    const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    if (textBufferEnabled)
    {
        if (!textBuffer)
        {
            textBuffer = List.initList!ubyte(DISPLAY_LINES * DISPLAY_COLUMNS * 2 * 5);
            List.push!ubyte(textBuffer, Ascii.LF);
            textBufferStartIndex = 0;
            textBufferEndIndex = textBufferStartIndex;
        }
        writeToTextBuffer(value);
    }

    textVideoMemoryPtr[position] = value;
    textVideoMemoryPtr[position + 1] = color;
}

private void printToTextVideoMemory(const ubyte value,
    const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    const size_t position = updateCoordinates;

    writeToTextVideoMemory(position, value, color);

    displayIndexX++;
    updateCursor;
}

void scroll(uint lines = 1)
{
    clearScreen;
}

void printCharRepeat(const char symbol, const size_t repeatCount = 1,
    const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{

    size_t count = repeatCount;
    const size_t maxChars = DISPLAY_COLUMNS * DISPLAY_LINES;
    if (count > maxChars)
    {
        count = maxChars;
    }

    foreach (index; 0 .. count)
    {
        printChar(symbol, color);
    }
}

void printChar(const char symbol, const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    if (symbol == Ascii.LF || symbol == Ascii.CR)
    {
        newLine;
        return;
    }

    if (displayIndexY > DISPLAY_LINES - 1)
    {
        scroll;
    }

    printToTextVideoMemory(symbol, color);
}

/*
* The symbol must be known at compile time.
* TextDrawer.drawUntil!('*', (symbol, symbolCount) => symbolCount <= 5); //*****
*/
void printCharUntil(const char symbol, bool function(const char,
        const size_t) symbolCountPredicate, const ubyte color = Display
        .CGAColors.DEFAULT_TEXT_COLOR)()
{
    size_t charsCount = 1;
    while (symbolCountPredicate(symbol, charsCount))
    {
        Display.printChar(symbol, color);
        charsCount++;
    }
}

void printString(const string str, const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    foreach (char c; str)
    {
        printChar(c, color);
    }
}

void printStringRepeat(const string str, const size_t repeatCount = 1,
    const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{

    size_t mustBeStringCount = repeatCount;
    const size_t maxStrings = (DISPLAY_LINES * DISPLAY_COLUMNS) / str.length;
    if (mustBeStringCount > maxStrings)
    {
        mustBeStringCount = maxStrings;
    }

    foreach (index; 0 .. mustBeStringCount)
    {
        printString(str, color);
    }
}

void println(const string str = "", const ubyte color = CGAColors.DEFAULT_TEXT_COLOR)
{
    printString(str, color);
    printChar(Ascii.LF);
}

void printSpace(const size_t count = 1, const char spaceChar = ' ')
{
    printCharRepeat(spaceChar, count);
}

void clearScreen(bool resetTextBuffer = true)
{
    bool isCursor = isCursorEnabled;
    if (isCursor)
    {
        disableCursor;
    }

    resetCoordinates;

    const isBuffer = textBufferEnabled;
    if (isBuffer)
    {
        textBufferEnabled = false;
    }

    immutable charCount = DISPLAY_COLUMNS * DISPLAY_LINES;
    foreach (index; 0 .. charCount)
    {
        //don't use black color
        printToTextVideoMemory(' ');
    }

    resetCoordinates;

    if (isBuffer)
    {
        textBufferEnabled = true;
        if (resetTextBuffer)
        {
            textBufferStartIndex = textBuffer.length == 0 ? 0 : textBuffer.length - 1;
            textBufferEndIndex = textBufferStartIndex;
            textBufferStatus = TextBufferWindowStatus.MIN;
        }
    }

    if (isCursor)
    {
        enableCursor;
    }
}

int getX() @nogc
{
    return displayIndexX;
}

int getY() @nogc
{
    return displayIndexY;
}

//TODO check value > 0
void setX(int value) @nogc
{
    displayIndexX = value;
}

void setY(int value) @nogc
{
    displayIndexY = value;
}

void setStartX(int value) @nogc
{
    displayStartIndexX = value;
}

void setStartY(int value) @nogc
{
    displayStartIndexY = value;
}

void setTextBufferEnabled(bool value) @nogc
{
    textBufferEnabled = value;
}

bool isTextBufferEnabled() @nogc
{
    return textBufferEnabled;
}

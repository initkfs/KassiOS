/**
 * Authors: initkfs
 */
module os.sys.term;

import std.traits;

private
{
    alias Allocator = os.core.mem.allocator;
    alias Display = os.core.graphic.text_display;
    alias Kstdio = os.std.io.kstdio;
    alias Keyboard = os.core.io.keyboard;
    alias List = os.std.container.linear_list;
    alias Ascii = os.std.text.ascii;
    alias GuiTextBox = os.std.gui.text.widget.box;
    alias Config = os.core.config.core_config;
    alias DateTime = os.std.date.datetime;
    alias SysTime = os.std.date.systime;
    alias Strings = os.std.text.strings;
    alias Shell = os.sys.kash.shell;
    alias Units = os.std.util.units;
    alias Inspector = os.core.support.inspector;

    const
    {
        __gshared string promptText = "$>";
    }

    __gshared bool active;

    __gshared ubyte promptColor = Display.CGAColors.DEFAULT_TEXT_COLOR;
    __gshared ubyte errorColor = Display.CGAInfoColors.COLOR_ERROR;
    __gshared ubyte infoColor = Display.CGAColors.DEFAULT_TEXT_COLOR;

    __gshared List.LinearList* textBuffer;
}

void start()
{
    Display.clearScreen;
    
    Display.setStartX(0);
    Display.setStartY(0);

    printHeader;
    
    int x, y;
    x = Display.getX;
    y = Display.getY;

    Display.setStartX(x);
    Display.setStartY(y);

    Display.setTextBufferEnabled(false);
    Display.enableCursor;

    printPrompt;
}

void printPrompt()
{
    Kstdio.kprint(promptText, promptColor);
    Display.enableCursor;
}

void clearScreen()
{
    Display.clearScreen;
}

void printHeader()
{
    const bool isBuffer = Display.isTextBufferEnabled;
    if(isBuffer){
        Display.setTextBufferEnabled(false);
    }

    const ubyte uiInfoColor = Display.CGAInfoColors.COLOR_INFO;

    size_t usedBytes, bufferedBytes, availableBytes;
    Allocator.getMemoryStat(usedBytes, bufferedBytes, availableBytes);

    auto dateTimeInfoPtr = DateTime.toIsoSimpleString(SysTime.getDateUtc);
    scope (exit)
    {
        Allocator.free(dateTimeInfoPtr);
    }

    auto lastCodeStr = Strings.toStringz(Shell.lastCode);
    scope (exit)
    {
        Allocator.free(lastCodeStr);
    }

    auto usedMemPtr = Units.formatBytes(usedBytes);
    scope (exit)
    {
        Allocator.free(usedMemPtr);
    }

    string statusInfo = Inspector.isErrors ? "Err" : "Ok";

    string[6] osInfoArgs = [
        Config.osName, Config.osVersion, Strings.toString(dateTimeInfoPtr),
        statusInfo, Strings.toString(usedMemPtr), Strings.toString(lastCodeStr)
    ];
    const osInfo = Strings.format("%s %s %s. %s. M:%s. RT:%s. Press Tab for help", osInfoArgs);
    scope (exit)
    {
        Allocator.free(osInfo);
    }
    GuiTextBox.simpleBox(Strings.toString(osInfo), uiInfoColor);

    if(isBuffer){
        Display.setTextBufferEnabled(true);
    }
}

private void resetTextBuffer()
{
    if (textBuffer !is null)
    {
        Allocator.free(textBuffer);
        textBuffer = null;
    }
}

void acceptInput(const ubyte keyCode)
{
    if (keyCode == 0x48)
    {
        Display.scrollToUp;
        return;
    }

    if (keyCode == 0x50)
    {
        Display.scrollToDown;
        return;
    }

    if (!isActive || Keyboard.isSpecial(keyCode))
    {
        return;
    }

    const char keyChar = Keyboard.getKeyByCode(keyCode);

    if ((keyChar == 'c' || keyChar == 'C') && Keyboard.isControlPress)
    {
        Display.clearScreen;
        printPrompt;
        return;
    }

    if (Keyboard.isUnrelated(keyChar))
    {
        return;
    }

    if (Ascii.isBackspace(keyChar))
    {
        Display.backspace(promptText.length);
        if (textBuffer !is null && !List.isEmpty(textBuffer))
        {
            char value;
            List.pop(textBuffer, value);
            if (List.isEmpty(textBuffer))
            {
                resetTextBuffer;
                return;
            }
        }
    }
    else if (keyChar == Ascii.TAB)
    {
        resetTextBuffer;
        printHelp;
    }
    else if (keyChar == Ascii.LF)
    {
        if (Display.getX == promptText.length)
        {
            return;
        }

        if (textBuffer !is null && !List.isEmpty(textBuffer))
        {
            string cmd = cast(string)(cast(ubyte*) textBuffer.data.ptr)[0 .. textBuffer.length];
            char* outResult;
            char* errResult;
            int returnCode = Shell.run(cmd, outResult, errResult);
            if (outResult || errResult)
            {
                Kstdio.kprintln;
            }

            if (outResult && Strings.lengthz(outResult) > 0)
            {
                Kstdio.kprintz(outResult);
            }

            if (errResult && Strings.lengthz(errResult) > 0)
            {
                if (outResult)
                {
                    Kstdio.kprintln;
                }
                Kstdio.kprintz(errResult, errorColor);
            }

            resetTextBuffer;
            Shell.resetResult;

            auto oldX = Display.getX;
            auto oldY = Display.getY;

            Display.setX(0);
            Display.setY(0);
            printHeader;
            Display.setX(oldX);
            Display.setY(oldY);

            //Check memory leak in terminal header after destroying buffers
            // alias free = os.sys.system.free;
            // char* a, b;
            // free.run("", a, b);
        }

        Display.newLine;
        printPrompt;
    }
    else
    {
        if (textBuffer is null)
        {
            textBuffer = List.initList!char(Display.DISPLAY_COLUMNS);
        }
        List.push!char(textBuffer, keyChar);
        Kstdio.kprint(keyChar);
    }
}

private void printHelp()
{

}

void setPromptColor(const ubyte color)
{
    promptColor = color;
}

void setErrorColor(const ubyte color)
{
    errorColor = color;
}

void setInfoColor(const ubyte color)
{
    infoColor = color;
}

void enable()
{
    active = true;
}

void disable()
{
    active = false;
}

bool isActive()
{
    return active;
}

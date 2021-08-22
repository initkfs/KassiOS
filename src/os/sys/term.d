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
    printHeader;
    printPrompt;
}

void printPrompt()
{
    Display.enableCursor;
    Kstdio.kprint(promptText, promptColor);
}

void printHeader()
{
    const ubyte uiInfoColor = Display.CGAInfoColors.COLOR_INFO;
    auto dateTimeInfoPtr = DateTime.toIsoSimpleString(SysTime.getDateUtc);
    scope (exit)
    {
        Allocator.free(dateTimeInfoPtr);
    }
    string[3] osInfoArgs = [
        Config.osName, Config.osVersion, Strings.toString(dateTimeInfoPtr)
    ];
    const osInfo = Strings.format("%s %s. %s. Press Tab for command help", osInfoArgs);
    scope (exit)
    {
        Allocator.free(osInfo);
    }
    GuiTextBox.simpleBox(Strings.toString(osInfo), uiInfoColor);
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
    if (!isActive || Keyboard.isSpecial(keyCode))
    {
        return;
    }

    const char keyChar = Keyboard.getKeyByCode(keyCode);
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
            scope (exit)
            {
                Shell.resetResult;
            }
            int returnCode = Shell.run(cmd, outResult, errResult);
            if (outResult || errResult)
            {
                Kstdio.kprintln;
            }

            if (outResult && Strings.strlength(outResult) > 0)
            {
                Kstdio.kprintz(outResult);
            }

            if (errResult && Strings.strlength(errResult) > 0)
            {
                if(outResult){
                    Kstdio.kprintln;
                }
                Kstdio.kprintz(errResult, errorColor);
            }

            resetTextBuffer;
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

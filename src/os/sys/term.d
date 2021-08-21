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
    alias LinearList = os.std.container.linear_list;
    alias Ascii = os.std.text.ascii;
    alias GuiTextBox = os.std.gui.text.widget.box;
    alias Config = os.core.config.core_config;
    alias DateTime = os.std.date.datetime;
    alias SysTime = os.std.date.systime;
    alias Strings = os.std.text.strings;

    const
    {
        __gshared string promptText = "$>";
    }

    __gshared bool active;

    __gshared ubyte promptColor = Display.CGAColors.DEFAULT_TEXT_COLOR;
    __gshared ubyte errorColor = Display.CGAInfoColors.COLOR_ERROR;
    __gshared ubyte infoColor = Display.CGAColors.DEFAULT_TEXT_COLOR;
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
    }
    else if (keyChar == Ascii.TAB)
    {
        printHelp;
    }
    else if (keyChar == Ascii.LF)
    {
        if (Display.getX == promptText.length)
        {
            return;
        }
        Display.newLine;
        printPrompt;
    }
    else
    {
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

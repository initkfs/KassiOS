/**
 * Authors: initkfs
 */
module os.std.gui.text.render;

private
{
    alias Display = os.core.graphic.text_display;
}

struct TextRenderSymbols
{
    enum NumberSign = '#';
}

void line(const char symbol = TextRenderSymbols.NumberSign, const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR)
{
    Display.printCharRepeat(symbol, Display.DISPLAY_COLUMNS, color);
}

void centerText(const string text, const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR,
        const size_t lineWidth = Display.DISPLAY_COLUMNS, const char indentSymbol = ' ')
{
    if (text.length == 0)
    {
        return;
    }

    size_t mustBeLineWidth = lineWidth;
    if (text.length > mustBeLineWidth)
    {
        mustBeLineWidth = text.length;
    }

    const leftAndRigthIndent = (mustBeLineWidth - text.length) / 2;

    Display.printCharRepeat(indentSymbol, leftAndRigthIndent);
    Display.printString(text, color);

    const rightPadIndent = mustBeLineWidth - text.length - leftAndRigthIndent;
    Display.printCharRepeat(indentSymbol, rightPadIndent);
}

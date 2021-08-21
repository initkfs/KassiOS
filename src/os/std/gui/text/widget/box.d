/**
 * Authors: initkfs
 */
module os.std.gui.text.widget.box;

private
{
    alias Display = os.core.graphic.text_display;
    alias Render = os.std.gui.text.render;
    const char sideSymbol = Render.TextRenderSymbols.NumberSign;
}

void boxTop(const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR,
        const char symbol = sideSymbol)
{
    Render.line(symbol, color);
}

void boxBottom(const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR,
        const char symbol = sideSymbol)
{
    Render.line(symbol, color);
}

void boxHeader(const string text = "",
        const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR, const char symbol = sideSymbol)
{
    const size_t lineWidth = Display.DISPLAY_COLUMNS - 2;
    Display.printChar(symbol, color);
    Render.centerText(text, color, lineWidth);
    Display.printChar(symbol, color);
}

void simpleBox(const string text = "",
        const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR, const char symbol = sideSymbol){
    boxTop(color, symbol);
	boxHeader(text, color, symbol);
	boxBottom(color, symbol);
}

void boxSides(const size_t sideHeight = 1,
        const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR, const char symbol = sideSymbol)
{
    const size_t symbolCount = Display.DISPLAY_COLUMNS;
    const size_t maxRightSymbolIndex = symbolCount - 1;

    //quadratic complexity O(N^2), but the box height will not be particularly large
    foreach (indexSide; 0 .. sideHeight)
    {
        foreach (indexSymbol; 0 .. symbolCount)
        {
            if (indexSymbol == 0 || indexSymbol == maxRightSymbolIndex)
            {
                Display.printChar(symbol, color);
            }
            else
            {
                Display.printSpace;
            }
        }
    }

}

void box(size_t height = 5, const ubyte color = Display.CGAColors.DEFAULT_TEXT_COLOR,
        const char symbol = sideSymbol)
{
    boxTop(color, symbol);
    boxSides(height, color, symbol);
    boxBottom(color, symbol);
}

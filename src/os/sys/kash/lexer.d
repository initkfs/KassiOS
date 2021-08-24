/**
 * Authors: initkfs
 */
module os.sys.kash.lexer;

import os.std.container.array_list;
import os.std.io.kstdio;
import os.std.math.math_core;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
}

enum TokenType
{
    NONE,
    NULL,
    WHITESPACE,
    NEWLINE,
    ID,
    NUMBER,
    PLUS,
    MINUS,
    TIMES,
    LPAREN,
    RPAREN,
    SEMICILON,
    COMMA,
    EQL,
    NEQ,
    LSS,
    GTR,
    LEQ,
    GEQ,
}

struct Token
{
    char* data;
    size_t length;
    TokenType type;
    bool isInit;
    Token* next;
}

struct Lexer
{
    Token* root;
}

TokenType getTokenTypeByChar(const char c)
{

    if (Ascii.isDecimalDigit(c))
    {
        return TokenType.NUMBER;
    }

    if (Ascii.isAlpha(c))
    {
        return TokenType.ID;
    }

    switch (c)
    {
    case Ascii.LF:
        return TokenType.NEWLINE;
    case ' ':
        return TokenType.WHITESPACE;
    case '+':
        return TokenType.PLUS;
    case '-':
        return TokenType.MINUS;
    case '*':
        return TokenType.TIMES;
    case '(':
        return TokenType.LPAREN;
    case ')':
        return TokenType.RPAREN;
    case ';':
        return TokenType.SEMICILON;
    case ',':
        return TokenType.COMMA;
    case '=':
        return TokenType.EQL;
    case '<':
        return TokenType.LSS;
    case '>':
        return TokenType.GTR;
    case '\0':
        return TokenType.NULL;
    default:
    }

    return TokenType.NONE;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(getTokenTypeByChar(' ') == TokenType.WHITESPACE);
    kassert(getTokenTypeByChar('\n') == TokenType.NEWLINE);
    kassert(getTokenTypeByChar('\0') == TokenType.NULL);
    kassert(getTokenTypeByChar('d') == TokenType.ID);
    kassert(getTokenTypeByChar('7') == TokenType.NUMBER);
    kassert(getTokenTypeByChar('-') == TokenType.MINUS);
}

Token* createToken(TokenType type, Token* prev)
{
    auto token = createToken(type);
    prev.next = token;
    return token;
}

Token* createToken(TokenType type = TokenType.NONE)
{
    auto token = cast(Token*) Allocator.alloc(Token.sizeof);
    token.type = type;
    token.data = null;
    token.next = null;
    token.isInit = false;
    token.length = 0;

    return token;
}

void initToken(Token* token, size_t dataSize)
{
    token.data = cast(char*) Allocator.alloc(dataSize);
    token.length = dataSize;
    token.isInit = true;
}

string getTokenData(Token* token)
{
    if (token.length == 0)
    {
        return "";
    }
    return cast(string) token.data[0 .. token.length];
}

void deleteToken(Token* token)
{
    if (token is null)
    {
        return;
    }

    if (token.data)
    {
        Allocator.free(cast(size_t*) token.data);
    }

    deleteToken(token.next);

    Allocator.free(cast(size_t*) token);
}

void deleteLexer(Lexer* lexer)
{
    if (lexer.root)
    {
        deleteToken(lexer.root);
    }

    Allocator.free(cast(size_t*) lexer);
}

private Token* checkOrCreateToken(TokenType type, bool isPart, Token* oldToken)
{
    if (!oldToken)
    {
        return createToken(type);
    }

    if (oldToken.type == TokenType.NONE)
    {
        oldToken.type = type;
        return oldToken;
    }

    if (oldToken.type != type && !isPart)
    {
        return createToken(type, oldToken);
    }

    return oldToken;
}

private void flushTokenBuffer(Token* token, ref ArrayList!char tokenBuffer)
{
    if (tokenBuffer.isEmpty)
    {
        return;
    }

    if (!token.isInit)
    {
        initToken(token, tokenBuffer.length);
    }

    size_t index;
    foreach (chb; tokenBuffer)
    {
        Allocator.set(token.data, chb, cast(size_t*) token.data, index);
        index++;
    }
    tokenBuffer.clear;
}

private bool isTypeBufferNeeded(TokenType type){
    return type == TokenType.ID || type == TokenType.NUMBER;
}

private bool isBufferNeed(Token* token)
{
    return token && isTypeBufferNeeded(token.type);
}

void runLexer(string input, Lexer* lexer)
{
    if (lexer is null)
    {
        return;
    }

    lexer.root = createToken;

    // allocate the first token
    Token* token = lexer.root;
    bool isPartParsed;

    auto tokenBuffer = ArrayList!char(input.length);
    scope (exit)
    {
        tokenBuffer.free;
    }

    foreach (ch; input)
    {
        const type = getTokenTypeByChar(ch);

        if(isPartParsed && isBufferNeed(token) && !isTypeBufferNeeded(type)){
            flushTokenBuffer(token, tokenBuffer);
            isPartParsed = false;
        }

        switch (type)
        {
        case TokenType.ID:
            token = checkOrCreateToken(TokenType.ID, isPartParsed, token);
            tokenBuffer.push(ch);
            isPartParsed = true;
            break;
        case TokenType.NUMBER:
            token = checkOrCreateToken(TokenType.NUMBER, isPartParsed, token);
            tokenBuffer.push(ch);
            isPartParsed = true;
            break;
        case TokenType.WHITESPACE:
            break;
        case TokenType.MINUS:
            token = createToken(TokenType.MINUS, token);
            break;
        case TokenType.PLUS:
            token = createToken(TokenType.PLUS, token);
            break;
        default:
        }
    }

    if (isPartParsed && isBufferNeed(token))
    {
        flushTokenBuffer(token, tokenBuffer);
        isPartParsed = false;
    }
}

unittest
{
    import os.std.asserts : kassert;

    const input = " free  -h 512   -n  ";
    auto lexer = cast(Lexer*) Allocator.alloc(Lexer.sizeof);
    scope (exit)
    {
        deleteLexer(lexer);
    }

    runLexer(input, lexer);

    size_t index;
    auto token = lexer.root;
    while (token)
    {
        if (index == 0)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "free"));
        }
        else if (index == 1)
        {
            kassert(token.type == TokenType.MINUS);
        }
        else if (index == 2)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "h"));
        }
        else if (index == 3)
        {
            kassert(token.type == TokenType.NUMBER);
            kassert(Strings.isEquals(getTokenData(token), "512"));
        }
        else if (index == 4)
        {
            kassert(token.type == TokenType.MINUS);
        }
        else if (index == 5)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "n"));
        }

        index++;
        token = token.next;
    }

    kassert(index == 6);

    const operationInput = " 5+ 6  ";
    auto lexerCalc = cast(Lexer*) Allocator.alloc(Lexer.sizeof);
    scope (exit)
    {
        deleteLexer(lexerCalc);
    }

    runLexer(operationInput, lexerCalc);

    size_t calcIndex;
    auto calcToken = lexerCalc.root;
    kassert(calcToken !is null);
    while (calcToken)
    {
        if (calcIndex == 0)
        {
            kassert(calcToken.type == TokenType.NUMBER);
            kassert(Strings.isEquals(getTokenData(calcToken), "5"));
        }
        else if (calcIndex == 1)
        {
            kassert(calcToken.type == TokenType.PLUS);
        }
        else if (calcIndex == 2)
        {
            kassert(calcToken.type == TokenType.NUMBER);
            kassert(Strings.isEquals(getTokenData(calcToken), "6"));
        }

        calcIndex++;
        calcToken = calcToken.next;
    }

    kassert(calcIndex == 3);
}

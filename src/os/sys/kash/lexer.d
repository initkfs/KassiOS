/**
 * Authors: initkfs
 */
module os.sys.kash.lexer;

import os.std.container.array;
import os.std.container.array_list;
import os.std.io.kstdio;
import os.std.math.math_core;

import Strings = os.std.text.strings;
import Allocator = os.core.mem.allocator;
import Ascii = os.std.text.ascii;

enum TokenType
{
    NONE,
    NULL,
    WHITESPACE,
    NEWLINE,
    SEMICILON,
    DOT,
    COMMA,
    LPAREN,
    RPAREN,
    //math
    STAR,
    CARET,
    SLASH,
    PERCENT,
    PLUS,
    MINUS,
    //
    EQL,
    LSS,
    GTR,
    ID,
    NUMBER,
    NEQ,
    LEQ,
    GEQ,
}

enum LexerState
{
    NONE,
    START_TOKEN,
    END_TOKEN,
}

struct Token
{
    size_t id;
    Token* next;
    Token* prev;
    TokenType type;
    bool isInit;
    TokenData* dataPtr;
}

struct TokenData
{
    size_t length;
    char[0] data;
}

struct Lexer
{
    Token* root;
}

private bool isTypeBufferNeeded(const TokenType type) @nogc pure @safe
{
    return type >= TokenType.ID;
}

private bool isBufferNeed(const Token* token) @nogc pure @safe
{
    return token && isTypeBufferNeeded(token.type);
}

private bool isBufferFlushNeed(const Token* token, const TokenType nextType) @nogc pure @safe
{

    if (!token)
    {
        return false;
    }

    if (token.type == TokenType.NUMBER && (nextType == TokenType.DOT || nextType == TokenType.COMMA))
    {
        return false;
    }

    return isBufferNeed(token) && !isTypeBufferNeeded(nextType);
}

TokenType getTokenTypeByChar(const char c) @nogc pure @safe
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
        return TokenType.STAR;
    case '(':
        return TokenType.LPAREN;
    case ')':
        return TokenType.RPAREN;
    case ';':
        return TokenType.SEMICILON;
    case '.':
        return TokenType.DOT;
    case ',':
        return TokenType.COMMA;
    case '=':
        return TokenType.EQL;
    case '<':
        return TokenType.LSS;
    case '>':
        return TokenType.GTR;
    case '/':
        return TokenType.SLASH;
    case '%':
        return TokenType.PERCENT;
    case '^':
        return TokenType.CARET;
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

Token* createToken(const TokenType type = TokenType.NONE, Token* prev = null)
{
    auto token = cast(Token*) Allocator.alloc(Token.sizeof);
    token.id = 0;
    token.type = type;
    token.next = null;
    token.prev = null;
    token.isInit = false;
    token.dataPtr = null;

    if (prev)
    {
        token.prev = prev;
        prev.next = token;
        token.id = prev.id + 1;
    }

    return token;
}

Token* createToken(const TokenType type, Token* prev, const char value)
{
    auto token = createToken(type, prev);
    initToken(token, [value].staticArr);
    return token;
}

void initToken(Token* token, size_t dataLength)
{
    import MathStrict = os.std.math.math_strict;
    import os.std.errors;

    size_t buffSize;
    if (const sumErr = MathStrict.addExact(TokenData.sizeof, dataLength, buffSize))
    {
        panic(sumErr);
    }

    token.dataPtr = cast(TokenData*) Allocator.alloc(buffSize);
    token.dataPtr.length = dataLength;
    token.isInit = true;
}

void initToken(Token* token, const char[] data)
{
    initToken(token, data.length);
    foreach (i, ch; data)
    {
        token.dataPtr.data[i] = ch;
    }
}

string getTokenData(Token* token)
{
    if (!token.dataPtr || token.dataPtr.length == 0)
    {
        return "";
    }

    return cast(string) token.dataPtr.data[0 .. token.dataPtr.length];
}

unittest
{
    import os.std.asserts : kassert;

    Token* token = createToken(TokenType.ID);
    scope (exit)
    {
        deleteToken(token);
    }
    const string id = "foo barbaz";

    initToken(token, id);
    kassert(token.isInit);

    const string tokenId = getTokenData(token);
    kassert(Strings.isEquals(id, tokenId));
}

void deleteToken(Token* token)
{
    if (token is null)
    {
        return;
    }

    if (token.dataPtr)
    {
        Allocator.free(cast(size_t*) token.dataPtr);
    }

    Allocator.free(cast(size_t*) token);
}

void deleteLexer(Lexer* lexer)
{
    if (lexer.root)
    {
        Token* t = lexer.root;
        while (t)
        {
            Token* forDelete = t;
            t = forDelete.next;
            deleteToken(forDelete);
        }
    }

    Allocator.free(cast(size_t*) lexer);
}

private Token* checkOrCreateToken(TokenType type, LexerState lexerState, Token* prevToken)
{
    if (!prevToken)
    {
        return createToken(type);
    }

    if (lexerState == LexerState.END_TOKEN)
    {
        return createToken(type, prevToken);
    }

    if (prevToken.type == TokenType.NONE)
    {
        prevToken.type = type;
    }

    return prevToken;
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
        token.dataPtr.data[index] = chb;
        index++;
    }

    tokenBuffer.clear;
}

unittest
{
    import os.std.asserts : kassert;

    string input = "foo bar";
    auto tokenBuffer = ArrayList!char(input.length);
    scope (exit)
    {
        tokenBuffer.free;
    }
    foreach (ch; input)
    {
        if (const pushErr = tokenBuffer.push(ch))
        {
            kassert(false);
        }
    }

    Token* token = createToken(TokenType.ID);
    scope (exit)
    {
        deleteToken(token);
    }
    flushTokenBuffer(token, tokenBuffer);
    kassert(Strings.isEquals(getTokenData(token), input));
}

void runLexer(string input, Lexer* lexer)
{
    if (lexer is null)
    {
        return;
    }

    lexer.root = null;

    // allocate the first token
    Token* token;
    LexerState lexerState = LexerState.NONE;

    auto tokenBuffer = ArrayList!char(input.length);
    scope (exit)
    {
        tokenBuffer.free;
    }

    foreach (ch; input)
    {
        if (!lexer.root && token)
        {
            lexer.root = token;
        }

        const type = getTokenTypeByChar(ch);

        if (lexerState == LexerState.START_TOKEN && isBufferFlushNeed(token, type))
        {
            flushTokenBuffer(token, tokenBuffer);
            lexerState = LexerState.END_TOKEN;
        }

        //TODO remove code duplication
        switch (type)
        {
        case TokenType.ID:
            token = checkOrCreateToken(TokenType.ID, lexerState, token);
            tokenBuffer.push(ch);
            lexerState = LexerState.START_TOKEN;
            break;
        case TokenType.NUMBER:
            token = checkOrCreateToken(TokenType.NUMBER, lexerState, token);
            tokenBuffer.push(ch);
            lexerState = LexerState.START_TOKEN;
            break;
        case TokenType.DOT:
            if (lexerState == LexerState.START_TOKEN && token && token.type == TokenType.NUMBER)
            {
                tokenBuffer.push('.');
            }
            else
            {
                token = createToken(TokenType.DOT, token, ch);
            }
            break;
        case TokenType.COMMA:
            if (lexerState == LexerState.START_TOKEN && token && token.type == TokenType.NUMBER)
            {
                //',' => '.'
                tokenBuffer.push('.');
            }
            else
            {
                token = createToken(TokenType.COMMA, token, ch);
            }
            break;
        case TokenType.WHITESPACE:
            break;
        case TokenType.STAR:
            token = createToken(TokenType.STAR, token, ch);
            break;
        case TokenType.CARET:
            token = createToken(TokenType.CARET, token, ch);
            break;
        case TokenType.SLASH:
            token = createToken(TokenType.SLASH, token, ch);
            break;
        case TokenType.PERCENT:
            token = createToken(TokenType.PERCENT, token, ch);
            break;
        case TokenType.PLUS:
            token = createToken(TokenType.PLUS, token, ch);
            break;
        case TokenType.MINUS:
            token = createToken(TokenType.MINUS, token, ch);
            break;
        case TokenType.EQL:
            token = createToken(TokenType.EQL, token, ch);
            break;
        case TokenType.LPAREN:
            token = createToken(TokenType.LPAREN, token, ch);
            break;
        case TokenType.RPAREN:
            token = createToken(TokenType.RPAREN, token, ch);
            break;
        default:
        }
    }

    if (lexerState == LexerState.START_TOKEN && isBufferNeed(token))
    {
        flushTokenBuffer(token, tokenBuffer);
        lexerState = LexerState.END_TOKEN;
    }
}

unittest
{
    import os.std.asserts : kassert;

    const input = "free -h 512 -n ";
    auto lexer = cast(Lexer*) Allocator.alloc(Lexer.sizeof);
    scope (exit)
    {
        deleteLexer(lexer);
    }

    runLexer(input, lexer);

    size_t index;
    auto token = lexer.root;
    kassert(token.prev is null);
    kassert(token.next !is null);

    while (token)
    {
        if (index == 0)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "free"));
            kassert(token.prev is null);
            kassert(token.next !is null && token.next.type == TokenType.MINUS);
        }
        else if (index == 1)
        {
            kassert(token.type == TokenType.MINUS);
            kassert(token.prev && token.prev.type == TokenType.ID);
            kassert(token.next !is null && token.next.type == TokenType.ID);
        }
        else if (index == 2)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "h"));
            kassert(token.prev && token.prev.type == TokenType.MINUS);
            kassert(token.next !is null && token.next.type == TokenType.NUMBER);
        }
        else if (index == 3)
        {
            kassert(token.type == TokenType.NUMBER);
            kassert(Strings.isEquals(getTokenData(token), "512"));
            kassert(token.prev && token.prev.type == TokenType.ID);
            kassert(token.next !is null && token.next.type == TokenType.MINUS);
        }
        else if (index == 4)
        {
            kassert(token.type == TokenType.MINUS);
            kassert(token.prev && token.prev.type == TokenType.NUMBER);
            kassert(token.next !is null && token.next.type == TokenType.ID);
        }
        else if (index == 5)
        {
            kassert(token.type == TokenType.ID);
            kassert(Strings.isEquals(getTokenData(token), "n"));
            kassert(token.prev && token.prev.type == TokenType.MINUS);
            kassert(token.next is null);
        }

        index++;
        token = token.next;
    }

    kassert(index == 6);

    const operationInput = " 5,3+ 6  ";
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
            kassert(Strings.isEquals(getTokenData(calcToken), "5.3"));
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

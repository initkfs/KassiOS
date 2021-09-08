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

struct Token
{
    Token* next;
    Token* prev;
    size_t length;
    TokenType type;
    bool isInit;
    char* data;
}

struct Lexer
{
    Token* root;
}

private bool isTypeBufferNeeded(TokenType type)
{
    return type >= TokenType.ID;
}

private bool isBufferNeed(Token* token)
{
    return token && isTypeBufferNeeded(token.type);
}

private bool isBufferFlushNeed(Token* token, TokenType nextType)
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

Token* createToken(TokenType type, Token* prev)
{
    auto token = createToken(type);
    if (prev)
    {
        prev.next = token;
        token.prev = prev;
    }
    return token;
}

Token* createToken(TokenType type, Token* prev, char value)
{
    auto token = createToken(type, prev);
    initToken(token, 1);
    *token.data = value;
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

void runLexer(string input, Lexer* lexer)
{
    if (lexer is null)
    {
        return;
    }

    lexer.root = null;

    // allocate the first token
    Token* token;
    bool isPartParsed;

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

        if (isPartParsed && isBufferFlushNeed(token, type))
        {
            flushTokenBuffer(token, tokenBuffer);
            isPartParsed = false;
        }

        //TODO remove code duplication
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
        case TokenType.DOT:
            if (isPartParsed && token && token.type == TokenType.NUMBER)
            {
                tokenBuffer.push('.');
            }
            else
            {
                token = createToken(TokenType.DOT, token, ch);
            }
            break;
        case TokenType.COMMA:
            if (isPartParsed && token && token.type == TokenType.NUMBER)
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

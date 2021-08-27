/**
 * Authors: initkfs
 */
module os.sys.kash.parser.parser_core;

import os.sys.kash.lexer;

import std.traits;
import os.std.errors;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
    alias NumberOperationParser = os.sys.kash.parser.number_operation_parser;
}

enum AstNodeType
{
    VARIABLE_ASSIGNMENT,
    COMMAND_EXECUTE,
    NUMBER_OPERATION,
    CONSTANT,
    VARIABLE,
}

struct AstNode
{
    //TODO dangerous, double free() may work on this pointer 
    Token* token;
    AstNodeType type;
    AstNodeValue* value;
    AstNode* left;
    AstNode* right;
}

struct AstNodeValue
{
    TokenType type;
    size_t length;
    ubyte[0] data;
}

err runParser(Lexer* lexer, ref AstNode* resultNode)
{
    if (!lexer.root)
    {
        return error("Lexer root node is null");
    }

    auto token = lexer.root;
    err operationErr;
    if (NumberOperationParser.isNumberOperation(token))
    {
        operationErr = NumberOperationParser.parseNumberOperationExpression(token, resultNode);
    }
    else if (token.type == TokenType.ID && token.next is null)
    {
        operationErr = parseCommandExecuteExpression(token, resultNode);
    }
    return operationErr;
}

AstNode* createEmptyNode(AstNodeType type)
{
    auto node = cast(AstNode*) Allocator.alloc(AstNode.sizeof);
    node.token = null;
    node.type = type;
    node.value = null;
    node.left = null;
    node.right = null;
    return node;
}

AstNode* createAstNode(Token* token, AstNodeType type)
{
    auto node = createEmptyNode(type);
    node.token = token;

    if (type == AstNodeType.CONSTANT)
    {
        if (token.type == TokenType.NUMBER)
        {
            string tokenValue = getTokenData(token);
            //TODO integer
            import os.std.math.math_core : parseDouble;

            double value = parseDouble(tokenValue);
            setNodeValue(token.type, node, value);
        }
        else if (token.type == TokenType.ID)
        {
            string tokenValue = getTokenData(token);
            setNodeValue(token.type, node, tokenValue);
        }
    }

    return node;
}

AstNode* setNodeValue(T)(TokenType type, AstNode* node, T value)
{
    auto valueSize = value.sizeof;
    static if (is(T == string))
    {
        valueSize = value.length;
    }
    auto nodeValue = cast(AstNodeValue*) Allocator.alloc(AstNodeValue.sizeof + valueSize);
    nodeValue.type = type;
    static if (is(T == string))
    {
        ubyte* valuePtr = nodeValue.data.ptr;
        foreach (i, ubyte ch; value)
        {
            Allocator.set(valuePtr, ch, cast(size_t*) nodeValue, i);
        }
    }
    else
    {
        T* valuePtr = cast(T*) nodeValue.data.ptr;
        Allocator.set(valuePtr, value, cast(size_t*) nodeValue);
    }

    nodeValue.length = valueSize;
    node.value = nodeValue;
    return node;
}

bool isNext(Token* token)
{
    return token && token.next;
}

T getNodeValue(T)(AstNode* node)
{
    if (!node.value || !node.value.data.ptr)
    {
        return T.init;
    }

    size_t length = node.value.length;
    if (length == 0)
    {
        return T.init;
    }

    ubyte* dataPtr = node.value.data.ptr;

    static if (is(T == string))
    {
        return cast(string) dataPtr[0 .. length];
    }
    else
    {
        T* valuePtr = cast(T*) dataPtr;
        T value = cast(T)*valuePtr;
        return value;
    }
}

void deleteAstNode(AstNode* node)
{
    if (node is null)
    {
        return;
    }

    if (node.value)
    {
        Allocator.free(cast(size_t*) node.value);
    }

    deleteAstNode(node.left);
    deleteAstNode(node.right);

    Allocator.free(cast(size_t*) node);
}

err parseCommandExecuteExpression(Token* token, ref AstNode* node)
{
    auto execNode = createEmptyNode(AstNodeType.COMMAND_EXECUTE);
    auto leftNode = createAstNode(token, AstNodeType.CONSTANT);
    execNode.left = leftNode;
    //TODO args
    node = execNode;
    return null;
}

unittest
{
    import os.std.asserts : kassert;
    import os.std.io.kstdio;
    import os.std.text.strings;
    import os.std.math.math_core;

    const input = "5 + 6";
    auto lexer = cast(Lexer*) Allocator.alloc(Lexer.sizeof);
    scope (exit)
    {
        deleteLexer(lexer);
    }

    runLexer(input, lexer);

    AstNode* node;
    const parserErr = runParser(lexer, node);
    scope (exit)
    {
        deleteAstNode(node);
    }
    kassert(parserErr is null);
    kassert(node !is null);
    kassert(node.type == AstNodeType.NUMBER_OPERATION);
    kassert(node.token.type == TokenType.PLUS);

    kassert(node.left !is null);
    kassert(node.left.type == AstNodeType.CONSTANT);

    auto leftValue = getNodeValue!double(node.left);
    //TODO check random panic
    kassert(isEquals(leftValue, 5.0));

    kassert(node.right !is null);
    kassert(node.right.type == AstNodeType.CONSTANT);
    auto rightValue = getNodeValue!double(node.right);
    kassert(isEquals(rightValue, 6.0));
}

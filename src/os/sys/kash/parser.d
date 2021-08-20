/**
 * Authors: initkfs
 */
module os.sys.kash.parser;

import os.sys.kash.lexer;

import std.traits;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
}

enum AstNodeType
{
    COMMAND_EXECUTE,
    NUMBER_OPERATION,
    CONSTANT,
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

AstNode* createAstNode(Token* token, AstNodeType type)
{
    auto node = cast(AstNode*) Allocator.alloc(AstNode.sizeof);
    node.token = token;
    node.type = type;
    node.value = null;
    node.left = null;
    node.right = null;

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
    }

    return node;
}

AstNode* setNodeValue(T)(TokenType type, AstNode* node, T value)
{
    const valueSize = value.sizeof;
    auto nodeValue = cast(AstNodeValue*) Allocator.alloc(AstNodeValue.sizeof + valueSize);
    nodeValue.type = type;
    T* valuePtr = cast(T*) nodeValue.data.ptr;
    Allocator.set(valuePtr, value, cast(size_t*) nodeValue);
    nodeValue.length = valueSize;
    node.value = nodeValue;
    return node;
}

bool isNext(Token* token)
{
    return token && token.next;
}

bool isNumberOperation(Token* token)
{
    if (!token)
    {
        return false;
    }

    return token.type == TokenType.PLUS;
}

T getNodeValue(T)(AstNode* node)
{
    T* valuePtr = cast(T*) node.value.data.ptr;
    T value = cast(T)*valuePtr;
    return value;
}

AstNode* runParser(Lexer* lexer)
{
    if (!lexer.root)
    {
        return null;
    }

    auto token = lexer.root;
    if (token.type == TokenType.NUMBER && isNext(token) && isNumberOperation(token.next))
    {
        return parseNumberOperationExpression(token);
    }
    return null;
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

AstNode* parseNumberOperationExpression(Token* token)
{
    auto leftNode = createAstNode(token, AstNodeType.CONSTANT);

    auto operatorToken = token.next;
    auto operatorNode = createAstNode(operatorToken, AstNodeType.NUMBER_OPERATION);

    auto rightNode = createAstNode(operatorToken.next, AstNodeType.CONSTANT);

    operatorNode.left = leftNode;
    operatorNode.right = rightNode;
    return operatorNode;
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

    auto node = runParser(lexer);
    scope (exit)
    {
        deleteAstNode(node);
    }
    kassert(node !is null);
    kassert(node.type == AstNodeType.NUMBER_OPERATION);
    kassert(node.token.type == TokenType.PLUS);

    kassert(node.left !is null);
    kassert(node.left.type == AstNodeType.CONSTANT);

    auto leftValue = getNodeValue!double(node.left);
    kassert(isEqual(leftValue, 5.0));

    kassert(node.right !is null);
    kassert(node.right.type == AstNodeType.CONSTANT);
    auto rightValue = getNodeValue!double(node.right);
    kassert(isEqual(rightValue, 6.0));
}

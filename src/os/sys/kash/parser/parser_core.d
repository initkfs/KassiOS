/**
 * Authors: initkfs
 */
module os.sys.kash.parser.parser_core;

import std.traits;
import os.std.errors;

import Strings = os.std.text.strings;
import Allocator = os.core.mem.allocator;
import Ascii = os.std.text.ascii;
import NumberOperationParser = os.sys.kash.parser.number_operation_parser;
import VariableOperationParser = os.sys.kash.parser.variable_operation_parser;

import os.sys.kash.lexer;

enum AstNodeType
{
    COMMAND_EXECUTE,
    NUMBER_OPERATION,
    CONSTANT,
    NUMBER_CONSTANT,
    VARIABLE_ASSIGNMENT,
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

err runParser(Lexer* lexer, ref AstNode* resultNode, bool function(string) onCommandExists = null)
{
    if (!lexer.root)
    {
        return error("Lexer root node is null");
    }

    auto token = lexer.root;

    if (token.type == TokenType.ID)
    {
        const string commandName = getTokenData(token);
        if (onCommandExists && onCommandExists(commandName))
        {
            return parseCommandExecuteExpression(token, resultNode);
        }
        else
        {
            return error("Command does not exist");
        }
    }

    err operationErr;

    if (NumberOperationParser.isNumberOperation(token))
    {
        operationErr = NumberOperationParser.parseNumberOperationExpression(token, resultNode);
    }
    else if (VariableOperationParser.isVarOperation(token))
    {
        operationErr = VariableOperationParser.parseVarOperationExpression(token, resultNode);
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

    import MathStrict = os.std.math.math_strict;

    size_t buffSize;
    if (const sumErr = MathStrict.addExact(AstNodeValue.sizeof, valueSize, buffSize))
    {
        panic(sumErr);
    }

    auto nodeValue = cast(AstNodeValue*) Allocator.alloc(buffSize);
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

bool isNext(Token* token) @nogc pure @safe
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

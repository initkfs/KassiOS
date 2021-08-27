/**
 * Authors: initkfs
 */
module os.sys.kash.parser.number_operation_parser;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;

import std.traits;
import os.std.errors;

private
{
    alias Strings = os.std.text.strings;
    alias Ascii = os.std.text.ascii;
}

bool isNumberOperation(Token* token)
{
    if (!token)
    {
        return false;
    }

    return (token.type == TokenType.NUMBER || token.type == TokenType.ID)
        && isNext(token) && isNumberOperationType(token.next.type);
}

bool isNumberOperationType(TokenType type)
{
    if (!type)
    {
        return false;
    }

    return type >= TokenType.STAR && type <= TokenType.MINUS;
}

private err createNumberNode(Token* token, ref AstNode* result)
{
    if (token.type == TokenType.NUMBER)
    {
        result = createAstNode(token, AstNodeType.CONSTANT);
    }
    else if (token.type == TokenType.ID)
    {
        result = createAstNode(token, AstNodeType.VARIABLE);
    }
    else
    {
        return error("Unsupported token type for operations on numbers");
    }

    return null;
}

err parseNumberOperationExpression(Token* token, ref AstNode* result)
{
    AstNode* leftNode;
    const leftErr = createNumberNode(token, leftNode);
    if (leftErr)
    {
        return leftErr;
    }

    auto operatorToken = token.next;
    auto operatorNode = createAstNode(operatorToken, AstNodeType.NUMBER_OPERATION);

    AstNode* rightNode;
    const rightErr = createNumberNode(operatorToken.next, rightNode);
    if (rightErr)
    {
        return rightErr;
    }

    operatorNode.left = leftNode;
    operatorNode.right = rightNode;
    result = operatorNode;
    return null;
}

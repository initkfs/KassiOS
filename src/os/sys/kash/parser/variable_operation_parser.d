/**
 * Authors: initkfs
 */
module os.sys.kash.parser.variable_operation_parser;

import os.std.errors;

import Strings = os.std.text.strings;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;

bool isVarOperation(Token* token) @nogc pure @safe
{
    if (!token)
    {
        return false;
    }

    return token.type == TokenType.ID && isNext(token) && token.next.type == TokenType.EQL;
}

err parseVarOperationExpression(Token* token, ref AstNode* result)
{
    auto eqToken = token.next;
    auto varNode = createAstNode(eqToken, AstNodeType.VARIABLE_ASSIGNMENT);

    auto leftNode = createAstNode(token, AstNodeType.VARIABLE);
    varNode.left = leftNode;

    auto rightToken = eqToken.next;
    AstNode* rightNode;
    if (rightToken.type == TokenType.NUMBER)
    {
        rightNode = createAstNode(rightToken, AstNodeType.NUMBER_CONSTANT);
    }
    varNode.right = rightNode;

    result = varNode;
    return null;
}

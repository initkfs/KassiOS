/**
 * Authors: initkfs
 */
module os.sys.kash.parser.number_operation_parser;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;

import os.std.errors;

private
{
    alias Strings = os.std.text.strings;
}

bool isNumberOperation(Token* token)
{
    if (!token)
    {
        return false;
    }

    //TODO start at left parenthesis
    return (token.type == TokenType.NUMBER || token.type == TokenType.ID)
        && isNext(token) && isNumberOperationType(token.next.type);
}

bool isNumberOperationType(TokenType type)
{
    if (!type)
    {
        return false;
    }

    return type == TokenType.LPAREN || type == TokenType.RPAREN
        || (type >= TokenType.STAR && type <= TokenType.MINUS);
}

//TODO Simple forwarding of tokens to the executor
err parseNumberOperationExpression(Token* token, ref AstNode* result)
{
    result = createAstNode(token, AstNodeType.NUMBER_OPERATION);
    return null;
}

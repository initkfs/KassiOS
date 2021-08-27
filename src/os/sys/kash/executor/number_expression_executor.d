/**
 * Authors: initkfs
 */
module os.sys.kash.executor.number_expression_executor;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.errors;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
    alias Kstdio = os.std.io.kstdio;
    alias MathCore = os.std.math.math_core;
}

//TODO ingeter
err execute(AstNode* node, ref double result)
{
    return executeSingleOperation(node, result);
}

err executeSingleOperation(AstNode* node, ref double result)
{
    double leftValue = getNodeValue!double(node.left);
    double rigthValue = getNodeValue!double(node.right);
    switch (node.token.type)
    {
    case TokenType.PLUS:
        result = leftValue + rigthValue;
        break;
    case TokenType.MINUS:
        result = leftValue - rigthValue;
        break;
    case TokenType.STAR:
        result = leftValue * rigthValue;
        break;
    case TokenType.PERCENT:
        result = leftValue % rigthValue;
        break;
    case TokenType.CARET:
        //TODO integer base
        result = MathCore.pow(leftValue, cast(long)(rigthValue));
        break;
    default:
        return error("Unsupported numeric operator");
    }

    return null;
}

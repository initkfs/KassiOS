/**
 * Authors: initkfs
 */
module os.sys.kash.executor;

import os.sys.kash.lexer;
import os.sys.kash.parser;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
}

char* execute(AstNode* node)
{
    if (node.type == AstNodeType.NUMBER_OPERATION)
    {
        //TODO integer

        double result;
        double leftValue = getNodeValue!double(node.left);
        double rigthValue = getNodeValue!double(node.right);
        switch (node.token.type)
        {
        case TokenType.PLUS:
            result = leftValue + rigthValue;
            break;
        default:
        }

        return Strings.toString(result);
    }

    return null;
}

unittest
{
    import os.std.asserts : kassert;
    import os.std.io.kstdio;

    const input = " 5  +  6 ";
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

    auto result = execute(node);
    scope (exit)
    {
        Allocator.free(result);
    }
    kassert(result !is null);
    kassert(Strings.isEqual(Strings.toString(result), "11.0"));
}

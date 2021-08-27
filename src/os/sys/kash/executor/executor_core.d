/**
 * Authors: initkfs
 */
module os.sys.kash.executor.executor_core;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;

__gshared int lastResult;
__gshared char* outResult;
__gshared char* errResult;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
    alias Ascii = os.std.text.ascii;
    alias Kstdio = os.std.io.kstdio;
    alias NumberExpressionExecutor = os.sys.kash.executor.number_expression_executor;
    alias VarExecutor = os.sys.kash.executor.variable_executor;
}

void execute(AstNode* node, int function(string, ref char* outR,
        ref char* errR) onCommandExecute = null)
{
    if (node.type == AstNodeType.COMMAND_EXECUTE)
    {
        auto commandNode = node.left;
        string commandName = getNodeValue!string(commandNode);
        if (onCommandExecute)
        {
            lastResult = onCommandExecute(commandName, outResult, errResult);
        }
        return;
    }

    if (node.type == AstNodeType.VARIABLE_ASSIGNMENT)
    {
        const varErr = VarExecutor.execute(node, outResult);
        if (varErr)
        {
            lastResult = -1;
            errResult = Strings.toStringz(varErr);
            return;
        }

        lastResult = 0;
        return;
    }

    if (node.type == AstNodeType.NUMBER_OPERATION)
    {
        //TODO integer
        double result;
        const numberErr = NumberExpressionExecutor.execute(node, result);
        if (numberErr)
        {
            lastResult = -1;
            errResult = Strings.toStringz(numberErr);
            return;
        }

        outResult = Strings.toStringz(result);
        lastResult = 0;
        return;
        //return Strings.toString(result);
    }

    lastResult = -1;
    return;
}

void resetResult()
{
    lastResult = 0;
    if (outResult)
    {
        Allocator.free(outResult);
        outResult = null;
    }

    if (errResult)
    {
        Allocator.free(errResult);
        errResult = null;
    }
}

// unittest
// {
//     import os.std.asserts : kassert;

//     const input = " 5  +  6 ";
//     auto lexer = cast(Lexer*) Allocator.alloc(Lexer.sizeof);
//     scope (exit)
//     {
//         deleteLexer(lexer);
//     }

//     runLexer(input, lexer);

//     AstNode* node;
//     const parserErr = runParser(lexer, node);
//     scope (exit)
//     {
//         deleteAstNode(node);
//     }
//     kassert(parserErr is null);
//     execute(node);
//     kassert(lastResult == 0);
//     kassert(outResult !is null);
//     kassert(Strings.isEquals(Strings.toString(outResult), "11.0"));

//     resetResult;
//     kassert(lastResult == 0);
//     kassert(outResult is null);
//     kassert(errResult is null);
// }

/**
 * Authors: initkfs
 */
module os.sys.kash.executor.executor_core;

import os.std.container.array;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.container.hash_map;

import Strings = os.std.text.strings;
import Allocator = os.core.mem.allocator;
import Ascii = os.std.text.ascii;
import Kstdio = os.std.io.kstdio;
import NumberExpressionExecutor = os.sys.kash.executor.number_expression_executor;
import VarExecutor = os.sys.kash.executor.variable_executor;

__gshared
{
    int lastResult;
    char* outResult;
    char* errResult;
}

enum ExecutorResult : int
{
    SUCCESS = 0,
    ERROR = 1,
}

void execute(AstNode* node, int function(string, HashMap*, ref char* outR,
        ref char* errR) onCommandExecute = null)
{
    if (node.type == AstNodeType.COMMAND_EXECUTE)
    {
        auto commandNode = node.left;
        string commandName = getNodeValue!string(commandNode);

        HashMap* argsMap = HashMap.create(5);
        scope (exit)
        {
            HashMap.free(argsMap);
        }
        Token* currentToken = commandNode.token.next;
        bool parseArg;
        string argKey;
        while (currentToken)
        {
            if (currentToken.type == TokenType.ID && !currentToken.next)
            {
                argsMap.put!string(getTokenData(currentToken), "");
                break;
            }

            if (!parseArg)
            {
                if (currentToken.type == TokenType.MINUS && currentToken.next
                    && currentToken.next.type == TokenType.ID)
                {
                    parseArg = true;
                }
            }
            else
            {
                if (!argKey)
                {
                    argKey = getTokenData(currentToken);
                    if (!currentToken.next)
                    {
                        putCommandArg(argsMap, argKey, "", errResult);
                        break;
                    }
                    else
                    {
                        if (currentToken.next.type == TokenType.MINUS)
                        {
                            putCommandArg(argsMap, argKey, "", errResult);
                            argKey = null;
                            parseArg = false;
                        }
                    }
                }
                else
                {
                    const string argValue = getTokenData(currentToken);
                    putCommandArg(argsMap, argKey, argValue, errResult);
                    argKey = null;
                    parseArg = false;
                }
            }

            currentToken = currentToken.next;
        }

        if (onCommandExecute)
        {
            lastResult = onCommandExecute(commandName, argsMap, outResult, errResult);
        }
        return;
    }

    if (node.type == AstNodeType.VARIABLE_ASSIGNMENT)
    {
        if (const varErr = VarExecutor.execute(node, outResult))
        {
            lastResult = ExecutorResult.ERROR;
            errResult = Strings.toStringz(varErr);
            return;
        }

        lastResult = ExecutorResult.SUCCESS;
        return;
    }

    if (node.type == AstNodeType.NUMBER_OPERATION)
    {
        //TODO integer
        double result;
        if (const numberErr = NumberExpressionExecutor.execute(node, result))
        {
            lastResult = ExecutorResult.ERROR;
            errResult = Strings.toStringz(numberErr);
            return;
        }

        outResult = Strings.toStringz(result);
        lastResult = ExecutorResult.SUCCESS;
        return;
        //return Strings.toString(result);
    }

    lastResult = ExecutorResult.ERROR;
    return;
}

private void putCommandArg(HashMap* argsMap, string argKey, string value, ref char* err)
{
    if (argsMap.containsKey(argKey))
    {
        err = Strings.format("Error. duplicate argument received '%s'", [argKey].staticArr);
    }
    else
    {
        argsMap.put!string(argKey, value);
    }
}

void resetResult()
{
    lastResult = ExecutorResult.SUCCESS;
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

unittest
{
    import os.std.asserts : kassert;

    const input = " 5  +  6 * 3  + (4 + 3 ) * 2 + 5";
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
    execute(node);
    kassert(lastResult == ExecutorResult.SUCCESS);
    kassert(outResult !is null);
    kassert(Strings.isEquals(Strings.toString(outResult), "42.0"));

    resetResult;
    kassert(lastResult == ExecutorResult.SUCCESS);
    kassert(outResult is null);
    kassert(errResult is null);
}

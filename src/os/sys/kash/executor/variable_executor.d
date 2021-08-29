/**
 * Authors: initkfs
 */
module os.sys.kash.executor.variable_executor;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.errors;

private
{
    alias Strings = os.std.text.strings;
    alias MathCore = os.std.math.math_core;
    alias List = os.std.container.linked_list;

    __gshared List.LinkedList* varList;
}

bool hasVar(string varName)
{
    if (!varList)
    {
        return false;
    }

    return List.findItem(varList, varName) !is null;
}

T getVarValue(T)(string varName)
{
    auto item = List.findItem(varList, varName);
    if (!item)
    {
        return T.init;
    }
    //TODO check invalid types
    T value = cast(T) List.getItemData!T(item);
    return value;
}

err execute(AstNode* node, ref char* result)
{
    if (node.type == AstNodeType.VARIABLE_ASSIGNMENT)
    {
        string varName = getTokenData(node.left.token);

        auto valueNode = node.right;
        if (valueNode.type == AstNodeType.NUMBER_CONSTANT)
        {
            string valueStr = getTokenData(valueNode.token);
            const double value = MathCore.parseDouble(valueStr);

            if (!varList)
            {
                varList = List.createList;
            }

            List.addLast!double(varList, value, varName);
            string[2] varArgs = [varName, valueStr];
            result = Strings.format("%s = %s", varArgs);
        }
    }
    return null;
}

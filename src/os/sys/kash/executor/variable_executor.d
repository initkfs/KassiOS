/**
 * Authors: initkfs
 */
module os.sys.kash.executor.variable_executor;

import os.std.container.array;

import Strings = os.std.text.strings;
import MathCore = os.std.math.math_core;
import List = os.std.container.linked_list;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.errors;

private
{
    __gshared List.LinkedList* varList;
}

List.ListItem* hasVar(string varName)
{
    if (!varList)
    {
        return null;
    }

    auto item = varList.findItem(varName);
    return item;
}

bool hasVarDouble(string varName)
{
    auto item = hasVar(varName);
    return item !is null && item.type == List.ListItemType.FLOATING;
}

T getVarValue(T)(string varName)
{
    auto item = varList.findItem(varName);
    if (!item)
    {
        return T.init;
    }
    //TODO check invalid types
    T value = cast(T) varList.getItemData!T(item);
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
                varList = List.LinkedList.create;
            }

            varList.addLast!double(value, varName);
            result = Strings.format("%s = %s", [varName, valueStr].staticArr);
        }
    }
    return null;
}

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
    alias Map = os.std.container.hash_map;

    __gshared Map.HashMap* varMap;
}

bool hasVar(string varName)
{
    if (!varMap)
    {
        return false;
    }
    return Map.containsKey(varMap, varName);
}

T getVarValue(T)(string varName)
{
    if (!hasVar(varName))
    {
        return T.init;
    }
    //TODO check errors
    T value;
    Map.get!double(varMap, varName, value);

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
            double value = MathCore.parseDouble(valueStr);

            if (!varMap)
            {
                varMap = Map.initHashMap(10);
            }
            Map.put!double(varMap, varName, value);
            string[2] varArgs = [varName, valueStr];
            result = Strings.format("%s = %s", varArgs);
        }
    }
    return null;
}

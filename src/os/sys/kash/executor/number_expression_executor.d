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
    alias List = os.std.container.linked_list;
    alias Ascii = os.std.text.ascii;
    alias Kstdio = os.std.io.kstdio;
    alias MathCore = os.std.math.math_core;
    alias NumberOperationParser = os.sys.kash.parser.number_operation_parser;
    alias VarExecutor = os.sys.kash.executor.variable_executor;

    __gshared struct Operators
    {
        static const
        {
            char addition = '+';
            char subtraction = '-';
            char multiplication = '*';
            char division = '/';
            char divisionRemainder = '%';
            char exponentiation = '^';
            char leftParenthesis = '(';
            char rightParenthesis = ')';
        }

    }
}

//TODO ingeter
err execute(AstNode* node, ref double result)
{
    List.LinkedList* digitsStack = List.createList;
    List.LinkedList* operatorsStack = List.createList;
    scope (exit)
    {
        List.free(digitsStack);
        List.free(operatorsStack);
    }

    Token* currentToken = node.token;
    while (currentToken !is null)
    {
        if (NumberOperationParser.isNumberOperationType(currentToken.type))
        {
            //TODO check is empty
            const char expressionChar = getTokenData(currentToken)[0];

            if (expressionChar == Operators.leftParenthesis)
            {
                List.addLast!char(operatorsStack, Operators.leftParenthesis);
            }
            else if (expressionChar == Operators.rightParenthesis)
            {
                char last;
                auto lastItem = List.peekLast(operatorsStack);
                if (lastItem)
                {
                    last = List.getItemData!char(lastItem);
                }
                while (last != Operators.leftParenthesis)
                {
                    calculateOperation(digitsStack, operatorsStack);
                    lastItem = List.peekLast(operatorsStack);
                    if (lastItem)
                    {
                        last = List.getItemData!char(lastItem);
                    }
                }

                if (!List.isEmpty(operatorsStack))
                {
                    auto item = List.removeLast(operatorsStack);
                    List.freeListItem(item);
                }
            }
            else if (isOperator(expressionChar))
            {
                const char currentOperator = expressionChar;
                char last;
                auto lastItem = List.peekLast(operatorsStack);
                if (lastItem)
                {
                    last = List.getItemData!char(lastItem);
                }

                while (!List.isEmpty(operatorsStack)
                        && operatorPriority(last) >= operatorPriority(expressionChar))
                {
                    calculateOperation(digitsStack, operatorsStack);
                    lastItem = List.peekLast(operatorsStack);
                    if (lastItem)
                    {
                        last = List.getItemData!char(lastItem);
                    }
                }
                List.addLast!char(operatorsStack, currentOperator);
            }
        }
        else if (currentToken.type == TokenType.ID)
        {
            string varName = getTokenData(currentToken);
            if (!VarExecutor.hasVarDouble(varName))
            {
                return error("Not found numeric variable for number operation");
            }
            
            const double value = VarExecutor.getVarValue!double(varName);
            List.addLast!double(digitsStack, value);
        }
        else
        {
            const string valueStr = getTokenData(currentToken);
            const double value = MathCore.parseDouble(valueStr);
            List.addLast!double(digitsStack, value);
        }

        currentToken = currentToken.next;
    }

    while (!List.isEmpty(operatorsStack))
    {
        calculateOperation(digitsStack, operatorsStack);
    }

    auto lastItem = List.removeLast(digitsStack);
    if (!lastItem)
    {
        return error("Not found result");
    }
    scope (exit)
    {
        List.freeListItem(lastItem);
    }
    const double resultValue = List.getItemData!double(lastItem);
    result = resultValue;
    return null;
}

private bool isOperator(const char c) @safe pure nothrow
{
    foreach (operator; __traits(allMembers, Operators))
    {
        const auto operatorValue = __traits(getMember, Operators, operator);
        if (c == operatorValue)
        {
            return true;
        }
    }

    return false;
}

private int operatorPriority(char operator) @safe pure nothrow
{
    if (operator == Operators.addition || operator == Operators.subtraction)
    {
        return 1;
    }
    else if (operator == Operators.multiplication || operator == Operators.divisionRemainder
            || operator == Operators.division || operator == Operators.exponentiation)
    {
        return 2;
    }

    return 0;
}

private err calculateOperation(List.LinkedList* digitsStack, List.LinkedList* operatorStack)
{
    if (List.isEmpty(digitsStack))
    {
        return null;
    }

    auto operatorItem = List.removeLast(operatorStack);
    if (!operatorItem)
    {
        return error("Operator not found for calculation");
    }
    scope (exit)
    {
        List.freeListItem(operatorItem);
    }
    const char operator = List.getItemData!char(operatorItem);

    //first right
    auto rightNumber = List.removeLast(digitsStack);
    if (!rightNumber)
    {
        return error("Right number not found for calculation");
    }
    scope (exit)
    {
        List.freeListItem(rightNumber);
    }
    const double rightValue = List.getItemData!double(rightNumber);

    auto leftNumber = List.removeLast(digitsStack);
    if (!leftNumber)
    {
        return error("Left number not found for calculation");
    }
    scope (exit)
    {
        List.freeListItem(leftNumber);
    }
    const double leftValue = List.getItemData!double(leftNumber);

    double result = double.nan;
    switch (operator)
    {
    case Operators.addition:
        result = leftValue + rightValue;
        break;
    case Operators.subtraction:
        result = leftValue - rightValue;
        break;
    case Operators.multiplication:
        result = leftValue * rightValue;
        break;
    case Operators.division:
        result = leftValue / rightValue;
        break;
    case Operators.divisionRemainder:
        result = leftValue % rightValue;
        break;
    case Operators.exponentiation:
        //TODO validate exponent
        long exp = cast(long) rightValue;
        result = MathCore.pow(leftValue, exp);
        break;
    default:
    }

    List.addLast!double(digitsStack, result);

    return null;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isOperator('+'));
    kassert(isOperator('*'));
    kassert(isOperator('%'));

    auto digits = List.createList;
    auto operators = List.createList;
    scope (exit)
    {
        List.free(digits);
        List.free(operators);
    }

    List.addLast!double(digits, 2.45);
    List.addLast!double(digits, 3.3);
    List.addLast!char(operators, '+');
    auto opErr = calculateOperation(digits, operators);
    kassert(opErr is null);

    auto lastItem = List.peekLast(digits);
    kassert(lastItem !is null);
    const double result = List.getItemData!double(lastItem);
    kassert(MathCore.isEquals(result, 5.75));
}

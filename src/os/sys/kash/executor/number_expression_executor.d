/**
 * Authors: initkfs
 */
module os.sys.kash.executor.number_expression_executor;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.errors;

import Strings = os.std.text.strings;
import Allocator = os.core.mem.allocator;
import List = os.std.container.linked_list;
import Ascii = os.std.text.ascii;
import Kstdio = os.std.io.kstdio;
import MathCore = os.std.math.math_core;
import NumberOperationParser = os.sys.kash.parser.number_operation_parser;
import VarExecutor = os.sys.kash.executor.variable_executor;

private
{
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
    List.LinkedList* digitsStack = List.LinkedList.create;
    List.LinkedList* operatorsStack = List.LinkedList.create;
    scope (exit)
    {
        List.LinkedList.free(digitsStack);
        List.LinkedList.free(operatorsStack);
    }

    Token* currentToken = node.token;
    bool isNeg;
    while (currentToken !is null)
    {
        if (NumberOperationParser.isNumberOperationType(currentToken.type))
        {
            //TODO check is empty
            const char expressionChar = getTokenData(currentToken)[0];

            if (expressionChar == Operators.leftParenthesis)
            {
                operatorsStack.addLast!char(Operators.leftParenthesis);
            }
            else if (expressionChar == Operators.rightParenthesis)
            {
                char last;
                if (auto lastItem = operatorsStack.peekLast)
                {
                    last = operatorsStack.getItemData!char(lastItem);
                }
                while (last != Operators.leftParenthesis)
                {
                    calculateOperation(digitsStack, operatorsStack);
                    if (auto lastItem = operatorsStack.peekLast)
                    {
                        last = operatorsStack.getItemData!char(lastItem);
                    }
                }

                if (!operatorsStack.isEmpty)
                {
                    auto item = operatorsStack.removeLast;
                    operatorsStack.freeListItem(item);
                }
            }
            else if (isOperator(expressionChar))
            {
                const char currentOperator = expressionChar;

                if (NumberOperationParser.isUnaryNumberOperation(currentToken))
                {
                    isNeg = currentToken.type == TokenType.MINUS;
                    currentToken = currentToken.next;
                    continue;
                }

                char last;
                if (auto lastItem = operatorsStack.peekLast)
                {
                    last = operatorsStack.getItemData!char(lastItem);
                }

                while (!operatorsStack.isEmpty
                        && operatorPriority(last) >= operatorPriority(expressionChar))
                {
                    calculateOperation(digitsStack, operatorsStack);
                    if (auto lastItem = operatorsStack.peekLast)
                    {
                        last = operatorsStack.getItemData!char(lastItem);
                    }
                }
                operatorsStack.addLast!char(currentOperator);
            }
        }
        else if (currentToken.type == TokenType.ID)
        {
            string varName = getTokenData(currentToken);
            if (!VarExecutor.hasVarDouble(varName))
            {
                return error("Not found numeric variable for number operation");
            }

            double value = VarExecutor.getVarValue!double(varName);
            if (isNeg)
            {
                value = -value;
            }
            digitsStack.addLast!double(value);
            isNeg = false;
        }
        else
        {
            const string valueStr = getTokenData(currentToken);
            double value = MathCore.parseDouble(valueStr);
            if (isNeg)
            {
                value = -value;
            }
            digitsStack.addLast!double(value);
            isNeg = false;
        }

        currentToken = currentToken.next;
    }

    while (!operatorsStack.isEmpty)
    {
        calculateOperation(digitsStack, operatorsStack);
    }

    auto lastItem = digitsStack.removeLast;
    if (!lastItem)
    {
        return error("Not found result");
    }
    scope (exit)
    {
        digitsStack.freeListItem(lastItem);
    }
    const double resultValue = digitsStack.getItemData!double(lastItem);
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
    if (digitsStack.isEmpty)
    {
        return null;
    }

    auto operatorItem = operatorStack.removeLast;
    if (!operatorItem)
    {
        return error("Operator not found for calculation");
    }
    scope (exit)
    {
        operatorStack.freeListItem(operatorItem);
    }
    const char operator = operatorStack.getItemData!char(operatorItem);

    //first right
    auto rightNumber = digitsStack.removeLast;
    if (!rightNumber)
    {
        return error("Right number not found for calculation");
    }
    scope (exit)
    {
        digitsStack.freeListItem(rightNumber);
    }
    const double rightValue = digitsStack.getItemData!double(rightNumber);

    auto leftNumber = digitsStack.removeLast;
    if (!leftNumber)
    {
        return error("Left number not found for calculation");
    }
    scope (exit)
    {
        digitsStack.freeListItem(leftNumber);
    }
    const double leftValue = digitsStack.getItemData!double(leftNumber);

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

    digitsStack.addLast!double(result);

    return null;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isOperator('+'));
    kassert(isOperator('*'));
    kassert(isOperator('%'));

    auto digits = List.LinkedList.create;
    auto operators = List.LinkedList.create;
    scope (exit)
    {
        List.LinkedList.free(digits);
        List.LinkedList.free(operators);
    }

    digits.addLast!double(2.45);
    digits.addLast!double(3.3);
    operators.addLast!char('+');
    auto opErr = calculateOperation(digits, operators);
    kassert(opErr is null);

    auto lastItem = digits.peekLast;
    kassert(lastItem !is null);
    const double result = digits.getItemData!double(lastItem);
    kassert(MathCore.isEquals(result, 5.75));
}

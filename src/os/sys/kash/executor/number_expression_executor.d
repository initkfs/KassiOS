/**
 * Authors: initkfs
 */
module os.sys.kash.executor.number_expression_executor;

import os.sys.kash.lexer;
import os.sys.kash.parser.parser_core;
import os.std.errors;
import os.std.container.array_list;

private
{
    alias Strings = os.std.text.strings;
    alias Allocator = os.core.mem.allocator;
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
    auto digitsStack = ArrayList!double(8);
    auto operatorsStack = ArrayList!char(8);
    scope (exit)
    {
        digitsStack.free;
        operatorsStack.free;
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
                auto pushError = operatorsStack.push(Operators.leftParenthesis);
                if (pushError)
                {
                    return pushError;
                }
            }
            else if (expressionChar == Operators.rightParenthesis)
            {
                char last;
                if (!operatorsStack.isEmpty)
                {
                    operatorsStack.last(last);
                }

                while (last != Operators.leftParenthesis)
                {
                    calculateOperation(digitsStack, operatorsStack);
                    if (!operatorsStack.isEmpty)
                    {
                        operatorsStack.last(last);
                    }
                }

                char popValue;
                if (!operatorsStack.isEmpty)
                {
                    operatorsStack.pop(popValue);
                }

            }
            else if (isOperator(expressionChar))
            {
                const char currentOperator = expressionChar;
                char last;
                if (!operatorsStack.isEmpty)
                {
                    operatorsStack.last(last);
                }

                while (!operatorsStack.isEmpty
                        && operatorPriority(last) >= operatorPriority(expressionChar))
                {
                    calculateOperation(digitsStack, operatorsStack);
                    if (!operatorsStack.isEmpty)
                    {
                        operatorsStack.last(last);
                    }
                }
                operatorsStack.push(currentOperator);
            }
        }
        else if (currentToken.type == TokenType.ID)
        {
            string varName = getTokenData(currentToken);
            if (!VarExecutor.hasVar(varName))
            {
                return error("Not found variable for number operation");
            }

            //TODO check type
            double value = VarExecutor.getVarValue!double(varName);
            auto digitPushErr = digitsStack.push(value);
            if (digitPushErr)
            {
                return digitPushErr;
            }
        }
        else
        {
            const string valueStr = getTokenData(currentToken);
            double value = MathCore.parseDouble(valueStr);
            auto digitPushErr = digitsStack.push(value);
            if (digitPushErr)
            {
                return digitPushErr;
            }
        }

        currentToken = currentToken.next;
    }

    while (!operatorsStack.isEmpty)
    {
        calculateOperation(digitsStack, operatorsStack);
    }

    double resultValue;
    auto resultErr = digitsStack.pop(resultValue);
    if (resultErr)
    {
        return resultErr;
    }

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

private err calculateOperation(ref ArrayList!double digitsStack, ref ArrayList!char operatorStack)
{
    if (digitsStack.isEmpty)
    {
        return null;
    }

    char operator;
    auto operatorErr = operatorStack.pop(operator);
    if (operatorErr)
    {
        return operatorErr;
    }

    //first right
    double rightDigit;
    auto rError = digitsStack.pop(rightDigit);
    if (rError)
    {
        return rError;
    }
    double leftDigit;
    auto lError = digitsStack.pop(leftDigit);
    if (lError)
    {
        return lError;
    }

    switch (operator)
    {
    case Operators.addition:
        digitsStack.push(leftDigit + rightDigit);
        break;
    case Operators.subtraction:
        digitsStack.push(leftDigit - rightDigit);
        break;
    case Operators.multiplication:
        digitsStack.push(leftDigit * rightDigit);
        break;
    case Operators.division:
        digitsStack.push(leftDigit / rightDigit);
        break;
    case Operators.divisionRemainder:
        digitsStack.push(leftDigit % rightDigit);
        break;
    case Operators.exponentiation:
        long exp = cast(long) rightDigit;
        digitsStack.push(MathCore.pow(leftDigit, exp));
        break;
    default:
        return null;
    }

    return null;
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isOperator('+'));
    kassert(isOperator('*'));
    kassert(isOperator('%'));

    auto digits = ArrayList!double(8);
    auto operators = ArrayList!char(8);
    scope (exit)
    {
        digits.free;
        operators.free;
    }

    digits.push(2.45);
    digits.push(3.3);
    operators.push('+');
    auto opErr = calculateOperation(digits, operators);
    kassert(opErr is null);

    double result;
    auto plusErr = digits.last(result);
    kassert(plusErr is null);
    kassert(MathCore.isEquals(result, 5.75));
}

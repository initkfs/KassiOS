/**
 * Authors: initkfs
 */
module os.sys.kash.shell;

import os.sys.kash.lexer;

import std.traits;

private
{
    alias Allocator = os.core.mem.allocator;
    alias KashLexer = os.sys.kash.lexer;
    alias KashParser = os.sys.kash.parser;
    alias KashExecutor = os.sys.kash.executor;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;

    alias Exit = os.sys.system.exit;
    alias Clear = os.sys.system.clear;
    alias Free = os.sys.system.free;

    //TODO replace with List
    public __gshared ShellCommand[3] shellCommands;
}

alias ShellCommandAction = int function(string args, ref char* outResult, ref char* inResult);

struct ShellCommand
{
    @property
    {
        string name;
        string desctiption;
        ShellCommandAction action;
    }

    this(string name, string desctiption, ShellCommandAction action)
    {
        this.name = name;
        this.desctiption = desctiption;
        this.action = action;
    }
}

void init()
{
    shellCommands[0] = ShellCommand("exit", "Immediate shutdown", &Exit.run);
    shellCommands[1] = ShellCommand("clear", "Clear screen", &Clear.run);
    shellCommands[2] = ShellCommand("free", "Print memory info", &Free.run);
}

int lastCode(){
    return KashExecutor.lastResult;
}

int run(string input, ref char* outResult, ref char* errResult)
{
    auto lexer = cast(KashLexer.Lexer*) Allocator.alloc(KashLexer.Lexer.sizeof);
    scope (exit)
    {
        KashLexer.deleteLexer(lexer);
    }

    KashLexer.runLexer(input, lexer);

    auto node = KashParser.runParser(lexer);
    scope (exit)
    {
        KashParser.deleteAstNode(node);
    }

    if (node is null)
    {
        errResult = Strings.toStringz("Invalid command received");
    }

    KashExecutor.execute(node, &onCommandExecute);
    outResult = KashExecutor.outResult;
    errResult = KashExecutor.errResult;

    return 0;
}

void resetResult()
{
    KashExecutor.resetResult;
}

int onCommandExecute(string commandName, ref char* outResult, ref char* errResult)
{
    foreach (command; shellCommands)
    {
        if (Strings.isEquals(command.name, commandName))
        {
            //TODO args
            auto result = command.action("", outResult, errResult);
            return result;
        }
    }
    return -1;
}

/**
 * Authors: initkfs
 */
module os.sys.kash.shell;

import os.sys.kash.lexer;
import os.std.container.hash_map;

import std.traits;

private
{
    alias Allocator = os.core.mem.allocator;
    alias KashLexer = os.sys.kash.lexer;
    alias KashParser = os.sys.kash.parser.parser_core;
    alias KashExecutor = os.sys.kash.executor.executor_core;
    alias Strings = os.std.text.strings;
    alias Kstdio = os.std.io.kstdio;

    alias Exit = os.sys.system.exit;
    alias Clear = os.sys.system.clear;
    alias Free = os.sys.system.free;
    alias Mount = os.sys.fs.mount;
    alias Unmount = os.sys.fs.unmount;
    alias Mkfile = os.sys.fs.mkfile;
    alias Ls = os.sys.fs.ls;

    //TODO replace with List
    public __gshared ShellCommand[7] shellCommands;
}

alias ShellCommandAction = int function(HashMap* args, ref char* outResult, ref char* inResult);

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
    shellCommands[3] = ShellCommand("mount", "Mount root filesystem", &Mount.run);
    shellCommands[4] = ShellCommand("unmount",
            "Unmount filesystem and delete all files", &Unmount.run);
    shellCommands[5] = ShellCommand("mkfile", "Create empty file", &Mkfile.run);
    shellCommands[6] = ShellCommand("ls", "Print list files", &Ls.run);
}

int lastCode()
{
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

    KashParser.AstNode* node;
    const parserErr = KashParser.runParser(lexer, node, (string commandName) {
        foreach (command; shellCommands)
        {
            if (Strings.isEquals(command.name, commandName))
            {
                return true;
            }
        }
        return false;
    });
    scope (exit)
    {
        KashParser.deleteAstNode(node);
    }

    if (parserErr)
    {
        errResult = Strings.toStringz(parserErr);
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

int onCommandExecute(string commandName, HashMap* args, ref char* outResult, ref char* errResult)
{
    foreach (command; shellCommands)
    {
        if (Strings.isEquals(command.name, commandName))
        {
            //TODO args
            auto result = command.action(args, outResult, errResult);
            return result;
        }
    }
    return -1;
}

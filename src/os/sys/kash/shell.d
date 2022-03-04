/**
 * Authors: initkfs
 */
module os.sys.kash.shell;

import os.sys.kash.lexer;
import os.std.container.hash_map;

import std.traits;

import Allocator = os.core.mem.allocator;
import KashLexer = os.sys.kash.lexer;
import KashParser = os.sys.kash.parser.parser_core;
import KashExecutor = os.sys.kash.executor.executor_core;
import Strings = os.std.text.strings;
import Kstdio = os.std.io.kstdio;

import Exit = os.sys.system.exit;
import Clear = os.sys.system.clear;
import Free = os.sys.system.free;
import Mount = os.sys.fs.mount;
import Unmount = os.sys.fs.unmount;
import Mkfile = os.sys.fs.mkfile;
import Ls = os.sys.fs.ls;

private
{
    //TODO replace with List
    __gshared ShellCommand[7] shellCommands;
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
        if(node){
            KashParser.deleteAstNode(node);
        }
    }

    if (parserErr)
    {
        errResult = Strings.toStringz(parserErr);
    }

    if(errResult){
        return 1;
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

/**
 * Authors: initkfs
 */
module os.sys.kash.shell;

import os.sys.kash.lexer;

import std.traits;

private
{
    alias Exit = os.sys.system.exit;


    //TODO replace with List
    public __gshared ShellCommand[1] shellCommands;
}

struct ShellCommand
{
    @property
    {
        string name;
        string desctiption;
        void function(string args) action;
    }

    this(string name, string desctiption, void function(string args) action)
    {
        this.name = name;
        this.desctiption = desctiption;
        this.action = action;
    }
}

void init()
{
    shellCommands[0] = ShellCommand("exit", "Immediate shutdown", &Exit.run);
}

int run(string input, ref char* outResult, ref char* errResult){
    auto com = shellCommands[0];
    com.action(input);
    return 0;
}

private void exitCommand(string args)
{
    import os.std.io.kstdio;
    kprintln("Exit");
}

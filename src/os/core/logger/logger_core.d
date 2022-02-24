/**
 * Authors: initkfs
 */
module os.core.logger.logger_core;

import std.traits;

import os.std.date.datetime;

enum LogLevel
{
    all,
    trace,
    info,
    warn,
    error
}

void getLevelName(const LogLevel level, out string name) @nogc pure @safe
{
    string levelName = "undefined.level";
    foreach (l; EnumMembers!LogLevel)
    {
        if (level == l)
        {
            levelName = l.stringof;
        }
    }
    name = levelName;
}

//minimal logger level >= global logger level
bool isForLogLevel(const LogLevel level, const LogLevel loggerLevel) @nogc pure @safe
{
    if (loggerLevel == LogLevel.all)
    {
        return true;
    }

    return level >= loggerLevel;
}

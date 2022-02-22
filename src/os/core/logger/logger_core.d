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

struct LogRecord
{
    const @property
    {
        LogLevel level;
        LocalDateTime datetime;
        string message;
        string file;
        int line;
    }

    this(string message, LogLevel level, LocalDateTime datetime, string file, int line) @nogc
    {
        this.level = level;
        this.datetime = datetime;
        this.message = message;
        this.file = file;
        this.line = line;
    }
}

string getLevelName(const LogLevel level) @nogc pure @safe
{
    string levelName = "undefined.level";
    foreach (l; EnumMembers!LogLevel)
    {
        if (level == l)
        {
            levelName = l.stringof;
        }
    }
    return levelName;
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

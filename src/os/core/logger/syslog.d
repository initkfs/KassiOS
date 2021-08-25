/**
 * Authors: initkfs
 */
module os.core.logger.syslog;

import os.core.logger.logger_core;

import std.traits;

private
{
    alias Allocator = os.core.mem.allocator;
    alias Serial = os.core.io.serial;
    alias DateTime = os.std.date.datetime;
    alias SysTime = os.std.date.systime;
    alias Strings = os.std.text.strings;
    alias Ascii = os.std.text.ascii;
    alias Inspector = os.core.support.inspector;

    __gshared LogLevel logLevel;
}

void setLoggerLevel(LogLevel level = LogLevel.all)
{
    logLevel = level;
}

string getLoggerLevelName()
{
    return getLevelName(logLevel);
}

bool isErrorLevel()
{
    return isForSyslogLevel(LogLevel.error);
}

bool isWarnLevel()
{
    return isForSyslogLevel(LogLevel.warn);
}

bool isInfoLevel()
{
    return isForSyslogLevel(LogLevel.info);
}

bool isTraceLevel()
{
    return isForSyslogLevel(LogLevel.trace);
}

bool isForSyslogLevel(LogLevel level)
{
    return isForLogLevel(level, logLevel);
}

private void log(LogLevel level, lazy string message, lazy string file, lazy int line)
{
    if (!isForLogLevel(level, logLevel))
    {
        return;
    }

    if (level == LogLevel.error)
    {
        Inspector.setErrors;
    }

    LogRecord record = LogRecord(message, level, SysTime.getDateTimeUtc, file, line);
    writeLogRecord(record);
}

private void logf(T)(LogLevel level, lazy string pattern, lazy T[] args,
        lazy string file, lazy int line)
{
    if (!isForLogLevel(level, logLevel))
    {
        return;
    }

    auto messagePtr = Strings.format!T(pattern, args);
    scope (exit)
    {
        Allocator.free(messagePtr);
    }
    const message = Strings.toString(messagePtr);
    log(level, message, file, line);
}

private void writeLogRecord(ref LogRecord record)
{
    const spaceChar = ' ';

    auto dateInfo = DateTime.toIsoSimpleString(record.datetime);
    scope (exit)
    {
        Allocator.free(dateInfo);
    }

    Serial.write(Strings.toString(dateInfo));
    Serial.write(spaceChar);
    Serial.write(getLevelName(record.level));
    Serial.write(spaceChar);
    Serial.write(record.message);
    Serial.write(spaceChar);
    Serial.write(record.file);
    Serial.write(':');

    auto lineInfo = Strings.toStringz(record.line);
    scope (exit)
    {
        Allocator.free(lineInfo);
    }
    Serial.write(Strings.toString(lineInfo));
    Serial.write(Ascii.LF);
}

void tracef(T)(lazy string pattern, T[] args, const string file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.trace, pattern, args, file, line);
}

void trace(lazy string message, const string file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.trace, message, file, line);
}

void trace(char* message, const string file = __FILE__, const int line = __LINE__)
{
    trace(Strings.toString(message), file, line);
}

void infof(T)(lazy string pattern, T[] args, const string file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.info, pattern, args, file, line);
}

void info(lazy string message, const string file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.info, message, file, line);
}

void info(char* message, const string file = __FILE__, const int line = __LINE__)
{
    info(Strings.toString(message), file, line);
}

void warnf(T)(lazy string pattern, T[] args, const string file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.warn, pattern, args, file, line);
}

void warn(lazy string message, const string file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.warn, message, file, line);
}

void warn(char* message, const string file = __FILE__, const int line = __LINE__)
{
    warn(Strings.toString(message), file, line);
}

void errorf(T)(lazy string pattern, T[] args, const string file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.error, pattern, args, file, line);
}

void error(lazy string message, const string file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.error, message, file, line);
}

void error(char* message, const string file = __FILE__, const int line = __LINE__)
{
    error(Strings.toString(message), file, line);
}

unittest
{
    import os.std.asserts : kassert;

    kassert(isForLogLevel(LogLevel.error, LogLevel.all));
    kassert(isForLogLevel(LogLevel.warn, LogLevel.all));
    kassert(isForLogLevel(LogLevel.info, LogLevel.all));
    kassert(isForLogLevel(LogLevel.trace, LogLevel.all));
    kassert(isForLogLevel(LogLevel.all, LogLevel.all));

    kassert(isForLogLevel(LogLevel.error, LogLevel.error));
    kassert(!isForLogLevel(LogLevel.warn, LogLevel.error));
    kassert(!isForLogLevel(LogLevel.info, LogLevel.error));
    kassert(!isForLogLevel(LogLevel.trace, LogLevel.error));
    kassert(!isForLogLevel(LogLevel.all, LogLevel.error));

    kassert(isForLogLevel(LogLevel.error, LogLevel.warn));
    kassert(isForLogLevel(LogLevel.warn, LogLevel.warn));
    kassert(!isForLogLevel(LogLevel.info, LogLevel.warn));
    kassert(!isForLogLevel(LogLevel.trace, LogLevel.warn));
    kassert(!isForLogLevel(LogLevel.all, LogLevel.warn));

    kassert(isForLogLevel(LogLevel.error, LogLevel.info));
    kassert(isForLogLevel(LogLevel.warn, LogLevel.info));
    kassert(isForLogLevel(LogLevel.info, LogLevel.info));
    kassert(!isForLogLevel(LogLevel.trace, LogLevel.info));
    kassert(!isForLogLevel(LogLevel.all, LogLevel.info));

    kassert(isForLogLevel(LogLevel.error, LogLevel.trace));
    kassert(isForLogLevel(LogLevel.warn, LogLevel.trace));
    kassert(isForLogLevel(LogLevel.info, LogLevel.trace));
    kassert(isForLogLevel(LogLevel.trace, LogLevel.trace));
    kassert(!isForLogLevel(LogLevel.all, LogLevel.trace));

}

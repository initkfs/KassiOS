/**
 * Authors: initkfs
 */
module os.std.errors;

alias err = string;

private
{
  alias CoreConfig = os.core.config.core_config;
  alias Allocator = os.core.mem.allocator;
  alias Kstdio = os.std.io.kstdio;
  alias Strings = os.std.text.strings;
  alias Syslog = os.core.logger.syslog;
}

err error(const string message, const string file = __FILE__, const int line = __LINE__)
{

  if (CoreConfig.isLogGeneratedErrors && Syslog.isErrorLevel)
  {
    auto lineStr = Strings.toStringz(line);
    scope (exit)
    {
      Allocator.free(lineStr);
    }
    string[3] args = [message, file, Strings.toString(lineStr)];
    Syslog.errorf("Application error: %s, %s:%s", args);
  }

  return message;
}

void panic(const string message, const string file = __FILE__, const int line = __LINE__)
{
  auto lineStrPtr = Strings.toStringz(line);
  string lineStr = Strings.toString(lineStrPtr);
 
  if (Syslog.isErrorLevel)
  {
    string[3] args = [message, file, lineStr];
    Syslog.errorf("Panic: %s, %s:%s", args);
  }

  Kstdio.kprintln;
  Kstdio.kprint("PANIC: ");
  Kstdio.kprint(message);
  Kstdio.kprint(". ");
  Kstdio.kprint(file);
  Kstdio.kprint(":");
  Kstdio.kprint(lineStr);
  Kstdio.kprintln;
  
  Allocator.free(lineStrPtr);

  asm
  {
    cli;
    hlt;
  }
}

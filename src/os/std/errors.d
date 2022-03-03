/**
 * Authors: initkfs
 */
module os.std.errors;

alias err = string;

import CoreConfig = os.core.config.core_config;
import Allocator = os.core.mem.allocator;
import Kstdio = os.std.io.kstdio;
import Strings = os.std.text.strings;
import Syslog = os.core.logger.syslog;
import os.std.container.array;

err error(const string message, const string file = __FILE__, const int line = __LINE__)
{

  if (CoreConfig.isLogGeneratedErrors && Syslog.isErrorLevel)
  {
    auto lineStr = Strings.toStringz(line);
    scope (exit)
    {
      Allocator.free(lineStr);
    }
    Syslog.errorf("Application error: %s, %s:%s", [
        message, file, Strings.toString(lineStr)
      ].staticArr);
  }

  return message;
}

void panic(const string message, const string file = __FILE__, const int line = __LINE__)
{
  auto lineStrPtr = Strings.toStringz(line);
  string lineStr = Strings.toString(lineStrPtr);

  if (Syslog.isErrorLevel)
  {
    Syslog.errorf("Panic: %s, %s:%s", [message, file, lineStr].staticArr);
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

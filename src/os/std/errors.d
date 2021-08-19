/**
 * Authors: initkfs
 */
module os.std.errors;

alias err = string;

private
{
  alias Allocator = os.core.mem.allocator;
  alias Kstdio = os.std.io.kstdio;
  alias Strings = os.std.text.strings;
}

err error(const string message, const string file = __FILE__, const int line = __LINE__)
{
  return message;
}

void panic(const string message, const string file = __FILE__, const int line = __LINE__)
{
  Kstdio.kprint("PANIC: ");
  Kstdio.kprint(message);
  Kstdio.kprint(". ");
  Kstdio.kprint(file);
  Kstdio.kprint(":");
  auto fileLinePtr = Strings.toString(line);
  Kstdio.kprint(fileLinePtr);
  Allocator.free(fileLinePtr);

  asm
  {
    cli;
    hlt;
  }
}

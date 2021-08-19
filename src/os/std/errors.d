/**
 * Authors: initkfs
 */
module os.std.errors;

alias err = string;

private
{
  alias Kstdio = os.std.io.kstdio;
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

  asm
  {
    cli;
  }
  while (true)
  {
  }
}

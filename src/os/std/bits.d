/**
 * Authors: initkfs
 */
module os.std.bits;

import std.traits;

bool isBitSet(T)(T bits, T n) @nogc pure @safe if (isIntegral!T)
{
  return (bits & (1 << n)) != 0;
}

unittest
{
  import os.std.asserts : kassert;

  kassert(isBitSet(1, 0));
  kassert(isBitSet(2, 1));
  kassert(isBitSet(4, 2));
  kassert(isBitSet(128, 7));
}

T setBit(T)(T bits, T n) @nogc pure @safe if (isIntegral!T)
{
  return bits | (1 << n);
}

unittest
{
  import os.std.asserts : kassert;

  kassert(setBit(0, 0) == 1);
  kassert(setBit(0, 1) == 2);
  kassert(setBit(0, 4) == 16);
  kassert(setBit(0, 9) == 512);
  kassert(setBit(128, 3) == 136);
}

T unsetBit(T)(T bits, T n) @nogc pure @safe if (isIntegral!T)
{
  return bits & ~(1 << n);
}

unittest
{
  import os.std.asserts : kassert;

  //TODO check random panic
  kassert(unsetBit(3, 0) == 2);
  kassert(unsetBit(15, 2) == 11);
}

/**
 * Authors: initkfs
 */
module os.std.bits;

import std.traits;

bool isBitSet(T)(T bits, T n) if (isUnsigned!T)
{
  return (bits & (1 << n)) != 0;
}

unittest
{
  import os.std.asserts : kassert;

  kassert(isBitSet(1u, 0u));
  kassert(isBitSet(2u, 1u));
  kassert(isBitSet(4u, 2u));
  kassert(isBitSet(128u, 7u));
}

T setBit(T)(T bits, T n) if (isUnsigned!T)
{
  return bits | (1 << n);
}

unittest
{
  import os.std.asserts : kassert;

  kassert(setBit(0u, 0u) == 1u);
  kassert(setBit(0u, 1u) == 2u);
  kassert(setBit(0u, 4u) == 16u);
  kassert(setBit(0u, 9u) == 512u);
  kassert(setBit(128u, 3u) == 136u);
}

T unsetBit(T)(T bits, T n) if (isUnsigned!T)
{
  return bits & ~(1 << n);
}

unittest
{
  import os.std.asserts : kassert;

  kassert(unsetBit(3u, 0u) == 2u);
  kassert(unsetBit(15u, 2u) == 11u);
}

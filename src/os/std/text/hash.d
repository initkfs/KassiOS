/**
 * Authors: initkfs
 */
module os.std.text.hash;

import Allocator = os.core.mem.allocator;
import Strings = os.std.text.strings;

extern(C) uint jenkins(char* data);
unittest
{
    import os.std.asserts : kassert;

    auto s1 = Strings.toStringz("The quick brown fox jumps over the lazy dog");
    scope(exit){
        Allocator.free(s1);
    }
    auto hash1 = jenkins(s1);
    kassert(hash1 == 1369346549);
}

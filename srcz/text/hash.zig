const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn jenkins(dataPtr: [*:0]const u8) u32 {
    const data = mem.sliceTo(dataPtr, 0);
    const length: usize = data.len;

    if (length == 0) {
        return 0;
    }

    var hash: u32 = 0;
    var index: usize = 0;
    while (index < length) {
        hash +%= data[index];
        hash +%= hash << 10;
        hash ^= hash >> 6;
        index += 1;
    }

    hash +%= hash << 3;
    hash ^= hash >> 11;
    hash +%= hash << 15;

    return hash;
}

test "Test Jenkins hash" {
    try testing.expect(jenkins("") == 0);
    try testing.expect(jenkins("hello") == 3372029979);
    try testing.expect(jenkins("The quick brown fox jumps over the lazy dog") == 1369346549);
}

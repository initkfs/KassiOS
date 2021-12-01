const std = @import("std");
const mem = std.mem;

pub fn fromStringz(strPtr: [*:0]const u8) [:0]const u8 {
    return mem.sliceTo(strPtr, 0);
}

//pub use @import("./hash/hash.zig");
const hash = @import("./stdos/text/hash.zig");

export fn jenkins(data: [*:0]const u8) callconv(.C) u32 {
    return hash.jenkins(data);
}
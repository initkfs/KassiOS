//pub use @import("./hash/hash.zig");

const hash = @import("./text/hash.zig");

export fn jenkins(data: *u8) u32 {
    return hash.jenkins(data);
}
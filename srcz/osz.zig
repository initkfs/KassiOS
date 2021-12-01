//pub use @import("./hash/hash.zig");
const hash = @import("./stdos/text/hash.zig");

//See https://github.com/ziglang/zig/issues/5269 for callconv(.C)

//Hashes
export fn jenkins(data: [*:0]const u8) callconv(.C) u32 {
    return hash.jenkins(data);
}

export fn adler32(data: [*:0]const u8) callconv(.C) u32 {
    return hash.adler32(data);
}

export fn pjw32(data: [*:0]const u8) callconv(.C) u32 {
    return hash.jenkins(data);
}

export fn murmur32(data: [*:0]const u8) callconv(.C) u32 {
    return hash.murmur32(data);
}

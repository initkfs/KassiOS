const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    
    const target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
    };
    
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("osz", "srcz/osz.zig");
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();
}

const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    
    const target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
    };
    
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const libName = "osz";
    const mainFile = "srcz/osz.zig";

    const lib = b.addStaticLibrary(libName, mainFile);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest(mainFile);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

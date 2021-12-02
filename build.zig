const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    var features = std.Target.Cpu.Feature.Set.empty;
    features.addFeatureSet(std.Target.x86.cpu.x86_64.features);
    
    const target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
        .cpu_features_add = features,
    };
    
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const libName = "osz";
    const mainFile = "srcz/osz.zig";

    const lib = b.addStaticLibrary(libName, mainFile);
    lib.bundle_compiler_rt = true;
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest(mainFile);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

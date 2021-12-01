const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const strings = @import("./strings.zig");

pub fn jenkins(dataPtr: [*:0]const u8) u32 {
    const data: [:0]const u8 = strings.fromStringz(dataPtr);

    if (data.len == 0) {
        return 0;
    }

    var hash: u32 = 0;

    for (data) |ch| {
        hash +%= ch;
        hash +%= hash << 10;
        hash ^= hash >> 6;
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

pub fn adler32(dataPtr: [*:0]const u8) u32 {
    const data: [:0]const u8 = strings.fromStringz(dataPtr);

    if (data.len == 0) {
        return 0;
    }

    var s1: u32 = 1;
    var s2: u32 = 0;
    const rem = 65221;
    for (data) |ch| {
        s1 = (s1 + ch) % rem;
        s2 = (s2 + s1) % rem;
    }

    return (s2 << 16) | s1;
}

test "Test adler32 hash" {
    try testing.expect(adler32("") == 0);
    try testing.expect(adler32("hello") == 103547413);
    try testing.expect(adler32("hello world") == 436929629);
}

pub fn pjw32(dataPtr: [*:0]const u8) u32 {
    const data: [:0]const u8 = strings.fromStringz(dataPtr);

    if (data.len == 0) {
        return 0;
    }

    var hash: u32 = 0;
    var hashTest: u32 = 0;

    for (data) |ch| {
        hash = (hash << 4) +% ch;

        hashTest = hash & 0xf0000000;
        if (hashTest != 0) {
            hash = ((hash ^ (hashTest >> 24)) & (0xfffffff));
        }
    }

    return hash % @intCast(u32, data.len);
}

test "Test pjw32 hash" {
    try testing.expect(pjw32("") == 0);
    try testing.expect(pjw32("hello") == 2);
    try testing.expect(pjw32("hello world") == 6);
}

//Simple implementation prone to collisions
pub fn murmur32(dataPtr: [*:0]const u8) u32 {
    const data: [:0]const u8 = strings.fromStringz(dataPtr);
    const length: usize = data.len;

    if (length == 0) {
        return 0;
    }

    const m: u32 = 0x5bd1e995;
    const seed: u32 = 0;
    const r: i32 = 24;

    var hash: u32 = seed ^ @intCast(u32, length);

    var k: u32 = 0;
    var blockLength: usize = length;

    var i: usize = 0;
    while (blockLength >= 4) {
        k = data[i];
        //https://github.com/ziglang/zig/issues/6903
        k |= @as(u32, data[i + 1]) << 8;
        k |= @as(u32, data[i + 2]) << 16;
        k |= @as(u32, data[i + 3]) << 24;

        k *%= m;
        k ^= k >> r;
        k *%= m;

        hash *%= m;
        hash ^= k;

        i += 4;
        blockLength -= 4;
    }

    if (blockLength == 3) {
        hash ^= @as(u32, data[i + 2]) << 16;
    } else if (blockLength == 2) {
        hash ^= @as(u32, data[i + 1]) << 8;
    } else if (blockLength == 1) {
        hash ^= data[i];
        hash *%= m;
    }

    hash ^= hash >> 13;
    hash *%= m;
    hash ^= hash >> 15;

    return hash;
}

test "Test murmur32 hash" {
    try testing.expect(murmur32("") == 0);
    try testing.expect(murmur32("hello") == 3848350155);
    try testing.expect(murmur32("hello world") == 3930116263);
    try testing.expect(murmur32("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s") == 3150412050);
}

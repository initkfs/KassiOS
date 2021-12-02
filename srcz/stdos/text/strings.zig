const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const math = std.math;

const print = @import("std").debug.print;

pub fn fromStringz(strPtr: [*:0]const u8) [:0]const u8 {
    return mem.sliceTo(strPtr, 0);
}

export fn lengthz(strPtr: ?[*:0]const u8) callconv(.C) usize {
    if (strPtr) |str| {
        return fromStringz(str).len;
    }

    return 0;
}

export fn parseLong(num: i64, bufPtr: [*]u8, radix: i32) callconv(.C) [*:0]u8 {
    return parseInt(i64, num, bufPtr, radix);
}

fn parseInt(comptime T: type, num: i64, bufPtr: [*]u8, radix: i32) [*:0]u8 {
    const bufferSize = @sizeOf(T) * 8 + 3;

    const buf: *[bufferSize]u8 = bufPtr[0..bufferSize];

    var numArg: i128 = 0;
    var tailIndex: usize = 0;

    const endIndex: usize = bufferSize - 1;
    tailIndex = endIndex;

    buf[tailIndex] = 0;
    tailIndex -= 1;

    var base: i32 = radix;
    if (base > 36 or base < 2) {
       return @ptrCast([*:0]u8, bufPtr[(tailIndex + 1)..bufferSize]);
    }

    const isNeg: bool = num < 0;

    if (isNeg) {
        if (num == math.minInt(T)) {
            numArg = -(math.minInt(T));
        } else {
            numArg = -num;
        }
    } else {
        numArg = num;
    }

    if (numArg != 0) {
        while (numArg != 0) {
            var quot: i128 = @divTrunc(numArg, base);
            var rem: i128 = @rem(numArg, base);

            var numChar: i128 = rem;
            if (rem > 9) {
                numChar = numChar + ('A' - 10);
            } else {
                numChar = numChar + '0';
            }

            buf[tailIndex] = @intCast(u8, numChar);
            tailIndex -= 1;
            numArg = quot;
        }
    } else {
        //-0 == 0
        buf[tailIndex] = '0';
        tailIndex -= 1;
    }

    if (isNeg) {
        buf[tailIndex] = '-';
        tailIndex -= 1;
    }

    //TODO startIndex < endIndex
    return @ptrCast([*:0]u8, bufPtr[(tailIndex + 1)..bufferSize]);
}

test "Test parseInt" {
    var buff: [65:0]u8 = [_:0]u8{0} ** 65;
    var buffPtr: [*:0]u8 = @ptrCast([*:0]u8, &buff);

    const base10 = 10;
    const intType = i64;
    try testing.expect(fromStringz(parseInt(intType, 123, buffPtr, base10)).len == 3);
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, -0, buffPtr, base10)), "0"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 0, buffPtr, base10)), "0"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 1, buffPtr, base10)), "1"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, -1, buffPtr, base10)), "-1"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 267530967573, buffPtr, base10)), "267530967573"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, -6582967017365, buffPtr, base10)), "-6582967017365"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.maxInt(i64), buffPtr, base10)), "9223372036854775807"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.minInt(i64), buffPtr, base10)), "-9223372036854775808"));

    const base2 = 2;
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 1, buffPtr, base2)), "1"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 2, buffPtr, base2)), "10"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 346747, buffPtr, base2)), "1010100101001111011"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, -346747, buffPtr, base2)), "-1010100101001111011"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.maxInt(i64), buffPtr, base2)), "111111111111111111111111111111111111111111111111111111111111111"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.minInt(i64), buffPtr, base2)), "-1000000000000000000000000000000000000000000000000000000000000000"));

    const base16 = 16;
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 0, buffPtr, base16)), "0"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 1, buffPtr, base16)), "1"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 9, buffPtr, base16)), "9"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 10, buffPtr, base16)), "A"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 257785, buffPtr, base16)), "3EEF9"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.maxInt(i64), buffPtr, base16)), "7FFFFFFFFFFFFFFF"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.minInt(i64), buffPtr, base16)), "-8000000000000000"));

    const base8 = 8;
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 7, buffPtr, base8)), "7"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 8, buffPtr, base8)), "10"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, 56535, buffPtr, base8)), "156327"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.maxInt(i64), buffPtr, base8)), "777777777777777777777"));
    try testing.expect(mem.eql(u8, fromStringz(parseInt(intType, math.minInt(i64), buffPtr, base8)), "-1000000000000000000000"));
}

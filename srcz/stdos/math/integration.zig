const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;

fn f(x: f64) f64 {
    return 1 / (1 + x * x);
}

fn trapezoidal(a: f64, b: f64, n: i64) f64 {
    var h: f64 = (b - a) / @intToFloat(f64, n);
    var sum: f64 = f(a) + f(b);
    var i: usize = 1;
    while (i < n) : (i += 1) {
        sum += 2 * f(a + @intToFloat(f64, i) * h);
    }

    return (h / 2) * sum;
}

test "Test Trapezoidal Rule for integrals" {
    const a: f64 = 0;
    const b: f64 = 1;

    const result: f64 = trapezoidal(0, 1, 6);
    print("{d}\n", .{result});
    try testing.expect(result == 0.7842407666178157);
}

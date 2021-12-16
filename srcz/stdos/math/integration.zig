const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;

fn f(x: f64) f64 {
    return 1 / (1 + x * x);
}

fn trapezoidal(a: f64, b: f64, n: u32) f64 {
    var h: f64 = (b - a) / @intToFloat(f64, n);
    var sum: f64 = f(a) + f(b);
    var i: usize = 1;
    while (i < n) : (i += 1) {
        sum += 2 * f(a + @intToFloat(f64, i) * h);
    }

    return (h / 2) * sum;
}

test "Test Trapezoidal Rule for integrals" {
    const result: f64 = trapezoidal(0, 1, 6);
    //print("{d}\n", .{result});
    try testing.expect(result == 0.7842407666178157);
}

fn simpson(lower: f64, upper: f64, n: u32) f64 {
    
    if(n % 2 != 0){
        return 0;
    }
    
    var h: f64 = (upper - lower) / @intToFloat(f64, n);

    var x = [_]f64{0} ** 10;
    var fx = [_]f64{0} ** 10;

    var i: usize = 0;
    while (i <= n) : (i += 1) {
        x[i] = lower + @intToFloat(f64, i) * h;
        fx[i] = f(x[i]);
    }

    var res: f64 = 0;
    var j: usize = 0;
    while (j <= n) : (j += 1) {
        if (j == 0 or j == n) {
            res += fx[j];
        } else if (j % 2 != 0) {
            res += 4 * fx[j];
        } else {
            res += 2 * fx[j];
        }
    }

    res = res * (h / 3);
    return res;
}

test "Test Simpson's rule" {
    const result: f64 = simpson(0, 1, 6);
    //print("{d}\n", .{result});
    try testing.expect(result == 0.7853979452340107);
}

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;
const math = std.math;

const FunctionData = struct {
    x: f64,
    y: f64,
};

fn interpolateLagrange(f: []const FunctionData, xi: f64, n: i32) f64 {
    var result: f64 = 0;

    var i: usize = 0;
    while (i < n) : (i += 1) {
        var product: f64 = f[i].y;

        var j: usize = 0;
        while (j < n) : (j += 1) {
            if (j != i) {
                product = product * (xi - f[j].x) / (f[i].x - f[j].x);
            }
        }

        result += product;
    }

    return result;
}

//X: 0  1  2   5
//Y: 2  3  12  147
test "Test Lagrange interpolation" {
    const data = [_]FunctionData{
        .{ .x = 0, .y = 2 },
        .{ .x = 1, .y = 3 },
        .{ .x = 2, .y = 12 },
        .{ .x = 5, .y = 147 },
    };

    const dataValues = data[0..data.len];

    const result: f64 = interpolateLagrange(dataValues, 3, 4);
    //print("{d}\n", .{result});
    try testing.expect(result == 35);

    const result2: f64 = interpolateLagrange(dataValues, 4, 4);
    try testing.expect(math.approxEqAbs(f64, result2, 78, math.f32_epsilon));

    try testing.expect(false);
}

const std = @import("std");
const expect = std.testing.expect;
const sudoku = @import("sudoku.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{@as(i32, 1)});
}

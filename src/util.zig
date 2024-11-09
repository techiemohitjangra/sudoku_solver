const Sudoku = @import("sudoku.zig");
const std = @import("std");
const random = std.crypto.random;
const expect = std.testing.expect;

pub const Range = struct {
    start: u8,
    end: u8,
};

pub fn swapXOR(comptime T: type, first: *T, second: *T) void {
    switch (T) {
        Sudoku.SudokuCell => {
            first.*.value = second.*.value ^ first.*.value;
            second.*.value = second.*.value ^ first.*.value;
            first.*.value = second.*.value ^ first.*.value;
        },
        else => {
            first.* = second.* ^ first.*;
            second.* = second.* ^ first.*;
            first.* = second.* ^ first.*;
        },
    }
}

pub fn swap(comptime T: type, first: *T, second: *T) void {
    const temp: T = first.*;
    first.* = second.*;
    second.* = temp;
}

pub fn transpose(comptime T: type, sudoku: *[Sudoku.GRID_SIZE][Sudoku.GRID_SIZE]T) void {
    for (0..sudoku.len) |y| {
        for (y + 1..sudoku[y].len) |x| {
            if (x == y) {
                continue;
            } else {
                swap(T, &sudoku[y][x], &sudoku[x][y]);
            }
        }
    }
}

pub fn shuffle(comptime T: type, array: *[]T) void {
    for (array.len..0) |index| {
        const j: usize = random.uintLessThan(array.len);
        swap(array[index], array[j]);
    }
}

// test "shuffle function" {
//     var arr: [9]u8 = undefined;
//     for (&arr, 0..) |*value, index| {
//         value.* = @as(u8, @intCast(index + 1));
//     }
//     std.debug.print("{any}", .{arr});
// }

test "transpose function" {
    var mat: [Sudoku.GRID_SIZE][Sudoku.GRID_SIZE]u8 = [Sudoku.GRID_SIZE][Sudoku.GRID_SIZE]u8{
        [Sudoku.GRID_SIZE]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        [Sudoku.GRID_SIZE]u8{ 10, 11, 12, 13, 14, 15, 16, 17, 18 },
        [Sudoku.GRID_SIZE]u8{ 19, 20, 21, 22, 23, 24, 25, 26, 27 },
        [Sudoku.GRID_SIZE]u8{ 28, 29, 30, 31, 32, 33, 34, 35, 36 },
        [Sudoku.GRID_SIZE]u8{ 37, 38, 39, 40, 41, 42, 43, 44, 45 },
        [Sudoku.GRID_SIZE]u8{ 46, 47, 48, 49, 50, 51, 52, 53, 54 },
        [Sudoku.GRID_SIZE]u8{ 55, 56, 57, 58, 59, 60, 61, 62, 63 },
        [Sudoku.GRID_SIZE]u8{ 64, 65, 66, 67, 68, 69, 70, 71, 72 },
        [Sudoku.GRID_SIZE]u8{ 73, 74, 75, 76, 77, 78, 79, 80, 81 },
    };
    const tranposedMat: [Sudoku.GRID_SIZE][Sudoku.GRID_SIZE]u8 = [Sudoku.GRID_SIZE][Sudoku.GRID_SIZE]u8{
        [Sudoku.GRID_SIZE]u8{ 1, 10, 19, 28, 37, 46, 55, 64, 73 },
        [Sudoku.GRID_SIZE]u8{ 2, 11, 20, 29, 38, 47, 56, 65, 74 },
        [Sudoku.GRID_SIZE]u8{ 3, 12, 21, 30, 39, 48, 57, 66, 75 },
        [Sudoku.GRID_SIZE]u8{ 4, 13, 22, 31, 40, 49, 58, 67, 76 },
        [Sudoku.GRID_SIZE]u8{ 5, 14, 23, 32, 41, 50, 59, 68, 77 },
        [Sudoku.GRID_SIZE]u8{ 6, 15, 24, 33, 42, 51, 60, 69, 78 },
        [Sudoku.GRID_SIZE]u8{ 7, 16, 25, 34, 43, 52, 61, 70, 79 },
        [Sudoku.GRID_SIZE]u8{ 8, 17, 26, 35, 44, 53, 62, 71, 80 },
        [Sudoku.GRID_SIZE]u8{ 9, 18, 27, 36, 45, 54, 63, 72, 81 },
    };
    transpose(u8, &mat);
    try expect(std.mem.eql([Sudoku.GRID_SIZE]u8, &mat, &tranposedMat));
}

test "swap function" {
    var a: u8 = 5;
    var b: u8 = 10;
    swap(u8, &a, &b);
    try expect(a == @as(u8, 10) and b == @as(u8, 5));
    swap(u8, &a, &b);
    try expect(a == @as(u8, 5) and b == @as(u8, 10));
}

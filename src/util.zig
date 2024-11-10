const sudoku = @import("sudoku.zig");
const std = @import("std");
const random = std.crypto.random;
const expect = std.testing.expect;

pub const Range = struct {
    start: u8,
    end: u8,
};

pub fn swapXOR(comptime T: type, first: *T, second: *T) void {
    switch (T) {
        sudoku.SudokuCell => {
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

pub fn transpose(comptime T: type, game: *[sudoku.GRID_SIZE][sudoku.GRID_SIZE]T) void {
    for (0..game.len) |y| {
        for (y + 1..game[y].len) |x| {
            if (x == y) {
                continue;
            } else {
                swap(T, &game[y][x], &game[x][y]);
            }
        }
    }
}

pub fn shuffle(comptime T: type, array: []T) void {
    var index: usize = array.len - 1;
    while (index > 0) : (index -= 1) {
        const j: usize = random.uintLessThan(u8, @intCast(array.len));
        swap(u8, &array[index], &array[j]);
    }
}

test "shuffle function" {
    var arr1: [9]u8 = [9]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const arr2: [9]u8 = [9]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };

    shuffle(u8, &arr1);

    try expect(!std.mem.eql(u8, &arr1, &arr2));
}

test "transpose function" {
    var mat: [sudoku.GRID_SIZE][sudoku.GRID_SIZE]u8 = [sudoku.GRID_SIZE][sudoku.GRID_SIZE]u8{
        [sudoku.GRID_SIZE]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        [sudoku.GRID_SIZE]u8{ 10, 11, 12, 13, 14, 15, 16, 17, 18 },
        [sudoku.GRID_SIZE]u8{ 19, 20, 21, 22, 23, 24, 25, 26, 27 },
        [sudoku.GRID_SIZE]u8{ 28, 29, 30, 31, 32, 33, 34, 35, 36 },
        [sudoku.GRID_SIZE]u8{ 37, 38, 39, 40, 41, 42, 43, 44, 45 },
        [sudoku.GRID_SIZE]u8{ 46, 47, 48, 49, 50, 51, 52, 53, 54 },
        [sudoku.GRID_SIZE]u8{ 55, 56, 57, 58, 59, 60, 61, 62, 63 },
        [sudoku.GRID_SIZE]u8{ 64, 65, 66, 67, 68, 69, 70, 71, 72 },
        [sudoku.GRID_SIZE]u8{ 73, 74, 75, 76, 77, 78, 79, 80, 81 },
    };
    const tranposedMat: [sudoku.GRID_SIZE][sudoku.GRID_SIZE]u8 = [sudoku.GRID_SIZE][sudoku.GRID_SIZE]u8{
        [sudoku.GRID_SIZE]u8{ 1, 10, 19, 28, 37, 46, 55, 64, 73 },
        [sudoku.GRID_SIZE]u8{ 2, 11, 20, 29, 38, 47, 56, 65, 74 },
        [sudoku.GRID_SIZE]u8{ 3, 12, 21, 30, 39, 48, 57, 66, 75 },
        [sudoku.GRID_SIZE]u8{ 4, 13, 22, 31, 40, 49, 58, 67, 76 },
        [sudoku.GRID_SIZE]u8{ 5, 14, 23, 32, 41, 50, 59, 68, 77 },
        [sudoku.GRID_SIZE]u8{ 6, 15, 24, 33, 42, 51, 60, 69, 78 },
        [sudoku.GRID_SIZE]u8{ 7, 16, 25, 34, 43, 52, 61, 70, 79 },
        [sudoku.GRID_SIZE]u8{ 8, 17, 26, 35, 44, 53, 62, 71, 80 },
        [sudoku.GRID_SIZE]u8{ 9, 18, 27, 36, 45, 54, 63, 72, 81 },
    };
    transpose(u8, &mat);
    try expect(std.mem.eql([sudoku.GRID_SIZE]u8, &mat, &tranposedMat));
}

test "swap function" {
    var a: u8 = 5;
    var b: u8 = 10;
    swap(u8, &a, &b);
    try expect(a == @as(u8, 10) and b == @as(u8, 5));
    swap(u8, &a, &b);
    try expect(a == @as(u8, 5) and b == @as(u8, 10));
}

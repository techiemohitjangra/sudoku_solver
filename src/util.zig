const Sudoku = @import("sudoku.zig");

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

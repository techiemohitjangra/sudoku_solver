const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const rand = std.crypto.random;

const SIZE: u8 = 9;
const MAX_CELL_VALUE: u8 = 9;
const MIN_CELL_VALUE: u8 = 1;
const DEFAULT_CELL_VALUE: u8 = 0;

const CellType = enum {
    Fixed,
    Variable,
};

const SudokuCell = struct {
    value: u8 = DEFAULT_CELL_VALUE,
    type: CellType = CellType.Variable,
};

pub fn swapXOR(comptime T: type, first: *T, second: *T) void {
    switch (T) {
        SudokuCell => {
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

pub fn transpose(comptime T: type, sudoku: *[SIZE][SIZE]T) void {
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

const Sudoku = struct {
    game: [SIZE][SIZE]SudokuCell = undefined,

    pub fn init(self: *Sudoku) void {
        _ = self.generate(0, 0);
    }

    // TODO: implement generate
    pub fn generate(self: *Sudoku, x: u8, y: u8) bool {
        _ = self;
        assert(x >= 0 and x < SIZE);
        assert(y >= 0 and y < SIZE);
        // for (0..SIZE)
        return false;
    }

    fn isValid(self: *Sudoku, value: u8, x: u8, y: u8) bool {
        assert(value >= MIN_CELL_VALUE and value <= MAX_CELL_VALUE);
        assert(x >= 0 and x < SIZE);
        assert(y >= 0 and y < SIZE);
        for (0..self.game[y].len) |tempX| {
            if (tempX == x) {
                continue;
            }
            if (self.game[y][tempX].value == value) {
                assert(self.game[y][tempX].value >= MIN_CELL_VALUE and self.game[y][tempX].value <= MAX_CELL_VALUE);
                return false;
            }
        }
        for (0..self.game.len) |tempY| {
            if (tempY == y) {
                continue;
            }
            if (self.game[tempY][x].value == value) {
                assert(self.game[tempY][x].value >= MIN_CELL_VALUE and self.game[tempY][x].value <= MAX_CELL_VALUE);
                return false;
            }
        }
        const startIndexX: u8 = @as(u8, x / 3) * 3;
        const startIndexY: u8 = @as(u8, y / 3) * 3;

        for (startIndexY..startIndexY + 3) |tempY| {
            for (startIndexX..startIndexX + 3) |tempX| {
                if (tempX == x and tempY == y) {
                    continue;
                }
                if (self.game[tempY][tempX].value == value) {
                    assert(self.game[tempY][tempX].value >= MIN_CELL_VALUE and self.game[tempY][tempX].value <= MAX_CELL_VALUE);
                    return false;
                }
            }
        }
        return true;
    }

    // Solves the sudoku regardless of the current state
    pub fn solve(self: *Sudoku) !void {
        const solved = self.solveNext(0, 0);
        if (solved and try self.isSolved()) {
            return;
        }
    }

    fn solveNext(self: *Sudoku, x: u8, y: u8) bool {
        assert(0 <= x and x < SIZE);
        assert(0 <= y and y < SIZE);
        if (y == SIZE - 1 and x == SIZE - 1) {
            for (1..SIZE + 1) |possibleValue| {
                assert(MIN_CELL_VALUE <= possibleValue and possibleValue <= MAX_CELL_VALUE);
                // std.log.err("possibleValue out of range on the last cell(x:{}, y:{}): {}\n", .{ x, y, possibleValue });
                if (self.isValid(@as(u8, @intCast(possibleValue)), x, y)) {
                    self.game[y][x].value = @as(u8, @intCast(possibleValue));
                    return true;
                }
            }
        }

        if (self.game[y][x].type == CellType.Fixed) {
            if (x < SIZE - 1) {
                if (self.solveNext(x + 1, y)) {
                    return true;
                }
            } else {
                if (self.solveNext(0, y + 1)) {
                    return true;
                }
            }
            return false;
        } else {
            for (1..SIZE + 1) |possibleValue| {
                assert(MIN_CELL_VALUE <= possibleValue and possibleValue <= MAX_CELL_VALUE);
                // std.log.err("possibleValue out of range(x:{}, y:{}): {}\n", .{ x, y, possibleValue });
                if (self.isValid(@as(u8, @intCast(possibleValue)), x, y)) {
                    self.game[y][x].value = @as(u8, @intCast(possibleValue));
                    if (x < SIZE - 1) {
                        if (self.solveNext(x + 1, y)) {
                            return true;
                        }
                    } else {
                        if (self.solveNext(0, y + 1)) {
                            return true;
                        }
                    }
                }
                self.game[y][x].value = @as(u8, 0);
            }
            return false;
        }
    }

    pub fn isSolved(self: *Sudoku) !bool {
        // assert(self.game);
        // checks if all the blocks are valid
        for (0..3) |blockY| {
            for (0..3) |blockX| {
                var hashMap = std.AutoHashMap(SudokuCell, bool).init(std.heap.c_allocator);
                for (0..3) |row| {
                    for (0..3) |col| {
                        try hashMap.put(self.game[(blockY * 3) + row][(blockX * 3) + col], true);
                    }
                }
                if (hashMap.count() != SIZE) return false;
            }
        }
        // checks if all the rows are valid
        for (self.game) |row| {
            for (row) |cell| {
                assert(cell.value >= MIN_CELL_VALUE and cell.value <= MAX_CELL_VALUE);
                var arr: [SIZE]bool = std.mem.zeroes([SIZE]bool);
                if (arr[cell.value - 1] == true) {
                    return false;
                }
                arr[cell.value - 1] = true;
            }
        }
        transpose(SudokuCell, &self.game);
        // checks if all the columns are valid
        for (self.game) |row| {
            for (row) |cell| {
                assert(cell.value >= MIN_CELL_VALUE and cell.value <= MAX_CELL_VALUE);
                var arr: [SIZE]bool = std.mem.zeroes([SIZE]bool);
                if (arr[cell.value - 1] == true) {
                    return false;
                }
                arr[cell.value - 1] = true;
            }
        }
        return true;
    }

    pub fn print(self: *const Sudoku) !void {
        // const stdout = std.io.getStdOut().writer();
        for (self.game) |row| {
            for (row) |cell| {
                std.debug.print("{any}, ", .{cell.value});
            }
            std.debug.print("\n", .{});
        }
    }
};

test "testing transpose function" {
    var mat: [SIZE][SIZE]u8 = [SIZE][SIZE]u8{
        [SIZE]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        [SIZE]u8{ 10, 11, 12, 13, 14, 15, 16, 17, 18 },
        [SIZE]u8{ 19, 20, 21, 22, 23, 24, 25, 26, 27 },
        [SIZE]u8{ 28, 29, 30, 31, 32, 33, 34, 35, 36 },
        [SIZE]u8{ 37, 38, 39, 40, 41, 42, 43, 44, 45 },
        [SIZE]u8{ 46, 47, 48, 49, 50, 51, 52, 53, 54 },
        [SIZE]u8{ 55, 56, 57, 58, 59, 60, 61, 62, 63 },
        [SIZE]u8{ 64, 65, 66, 67, 68, 69, 70, 71, 72 },
        [SIZE]u8{ 73, 74, 75, 76, 77, 78, 79, 80, 81 },
    };
    const tranposedMat: [SIZE][SIZE]u8 = [SIZE][SIZE]u8{
        [SIZE]u8{ 1, 10, 19, 28, 37, 46, 55, 64, 73 },
        [SIZE]u8{ 2, 11, 20, 29, 38, 47, 56, 65, 74 },
        [SIZE]u8{ 3, 12, 21, 30, 39, 48, 57, 66, 75 },
        [SIZE]u8{ 4, 13, 22, 31, 40, 49, 58, 67, 76 },
        [SIZE]u8{ 5, 14, 23, 32, 41, 50, 59, 68, 77 },
        [SIZE]u8{ 6, 15, 24, 33, 42, 51, 60, 69, 78 },
        [SIZE]u8{ 7, 16, 25, 34, 43, 52, 61, 70, 79 },
        [SIZE]u8{ 8, 17, 26, 35, 44, 53, 62, 71, 80 },
        [SIZE]u8{ 9, 18, 27, 36, 45, 54, 63, 72, 81 },
    };
    transpose(u8, &mat);
    try expect(std.mem.eql([SIZE]u8, &mat, &tranposedMat));
}

test "testing swap function" {
    var a: u8 = 5;
    var b: u8 = 10;
    swap(u8, &a, &b);
    try expect(a == @as(u8, 10) and b == @as(u8, 5));
    swap(u8, &a, &b);
    try expect(a == @as(u8, 5) and b == @as(u8, 10));
}

test "usage of ArrayHashMap" {
    const testAllocator = std.testing.allocator;
    var hashMap = std.AutoHashMap(u8, bool).init(testAllocator);
    defer hashMap.deinit();

    try hashMap.put(0, true);
    try hashMap.put(1, false);
}

test "isValid function test" {
    var game = Sudoku{};
    _ = game.init();
    try expect(!try game.isSolved());
}

test "solve function test" {
    var game = Sudoku{ .game = [SIZE][SIZE]SudokuCell{
        [SIZE]SudokuCell{ SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 4, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 7, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 1, .type = CellType.Fixed } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 1, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 9, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 9, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 1, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 7, .type = CellType.Fixed }, SudokuCell{ .value = 4, .type = CellType.Fixed } },
        [SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
    } };
    try game.solve();
    try expect(try game.isSolved());
}

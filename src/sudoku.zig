const std = @import("std");
const util = @import("util.zig");
const expect = std.testing.expect;
const assert = std.debug.assert;
const rand = std.crypto.random;

pub const GRID_SIZE: u8 = 9;
pub const MAX_CELL_VALUE: u8 = 9;
pub const MIN_CELL_VALUE: u8 = 1;
pub const DEFAULT_CELL_VALUE: u8 = 0;
pub const BLOCK_HEIGHT: u8 = 3;
pub const BLOCK_WIDTH: u8 = 3;
pub const BLOCK_COUNT_Y: u8 = 3;
pub const BLOCK_COUNT_X: u8 = 3;

pub const CellType = enum {
    Fixed,
    Variable,
};

pub const SudokuCell = struct {
    value: u8 = DEFAULT_CELL_VALUE,
    type: CellType = CellType.Variable,
};

pub const GameDifficulty = enum {
    Easy,
    Medium,
    Hard,

    pub fn getFillCellRange(self: GameDifficulty) util.Range {
        switch (self) {
            GameDifficulty.Easy => {
                return util.Range{ .start = 32, .end = 45 };
            },
            GameDifficulty.Medium => {
                return util.Range{ .start = 21, .end = 32 };
            },
            GameDifficulty.Hard => {
                return util.Range{ .start = 17, .end = 21 };
            },
        }
    }
};

pub const Sudoku = struct {
    state: [GRID_SIZE][GRID_SIZE]SudokuCell = undefined,
    difficulty: GameDifficulty = GameDifficulty.Easy,

    pub fn init(self: *Sudoku) void {
        self.clearAll();
        self.generate();
    }

    fn clearAll(self: *Sudoku) void {
        for (&self.state) |*row| {
            for (row) |*cell| {
                cell.value = 0;
                cell.type = CellType.Variable;
            }
        }
    }

    pub fn reset(self: *Sudoku) void {
        for (&self.state) |*row| {
            for (row) |*cell| {
                if (cell.type == CellType.Variable) {
                    cell.value = 0;
                }
            }
        }
    }

    fn generate(self: *Sudoku) void {
        var arr: [9]u8 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        util.shuffle(u8, &arr);
        // generate a completed and solved valid sudoku
        if (self._shuffle_generate(0, 0, &arr)) {
            self.solve();
            if (self.isSolved()) {
                self.reset();
            } else {
                std.log.err("generated sudoku not solved", .{});
            }
        }
        // randomly remove elements
        var count: usize = 81;
        const range = self.difficulty.getFillCellRange();
        const fillCount = rand.intRangeAtMost(u8, range.start, range.end);
        while (count > fillCount) {
            const x = rand.uintLessThan(u8, GRID_SIZE);
            const y = rand.uintLessThan(u8, GRID_SIZE);
            if (self.state[y][x].value != 0) {
                self.state[y][x].value = 0;
                self.state[y][x].type = CellType.Variable;
                count -= 1;
            }
        }
    }

    fn _shuffle_generate(self: *Sudoku, x: u8, y: u8, arr: []u8) bool {
        assert(0 <= x and x <= 8);
        assert(0 <= y and y <= 8);
        assert(arr.len == 9);
        util.shuffle(u8, arr);
        for (arr) |value| {
            if (self.isSafeValue(value, x, y)) {
                self.state[y][x].value = value;
                self.state[y][x].type = CellType.Fixed;
                if (x == GRID_SIZE - 1 and y == GRID_SIZE - 1) {
                    return true;
                }
                if (x < GRID_SIZE - 1) {
                    if (self._shuffle_generate(x + 1, y, arr)) {
                        return true;
                    }
                } else {
                    if (self._shuffle_generate(0, y + 1, arr)) {
                        return true;
                    }
                }
            }
        }
        self.state[y][x].value = 0;
        self.state[y][x].type = CellType.Variable;
        return false;
    }

    fn isSafeValue(self: *const Sudoku, value: u8, x: u8, y: u8) bool {
        assert(value >= MIN_CELL_VALUE and value <= MAX_CELL_VALUE);
        assert(x >= 0 and x < GRID_SIZE);
        assert(y >= 0 and y < GRID_SIZE);
        for (0..self.state[y].len) |tempX| {
            if (tempX == x) {
                continue;
            }
            if (self.state[y][tempX].value == value) {
                assert(self.state[y][tempX].value >= MIN_CELL_VALUE and self.state[y][tempX].value <= MAX_CELL_VALUE);
                return false;
            }
        }
        for (0..self.state.len) |tempY| {
            if (tempY == y) {
                continue;
            }
            if (self.state[tempY][x].value == value) {
                assert(self.state[tempY][x].value >= MIN_CELL_VALUE and self.state[tempY][x].value <= MAX_CELL_VALUE);
                return false;
            }
        }
        const startIndexX: u8 = @as(u8, x / BLOCK_WIDTH) * BLOCK_WIDTH;
        const startIndexY: u8 = @as(u8, y / BLOCK_HEIGHT) * BLOCK_HEIGHT;

        for (startIndexY..startIndexY + BLOCK_HEIGHT) |tempY| {
            for (startIndexX..startIndexX + BLOCK_WIDTH) |tempX| {
                if (tempX == x and tempY == y) {
                    continue;
                }
                if (self.state[tempY][tempX].value == value) {
                    assert(self.state[tempY][tempX].value >= MIN_CELL_VALUE and self.state[tempY][tempX].value <= MAX_CELL_VALUE);
                    return false;
                }
            }
        }
        return true;
    }

    // Solves the sudoku regardless of the current state
    pub fn solve(self: *Sudoku) void {
        const solved = self.solveNext(0, 0);
        if (solved and self.isSolved()) {
            return;
        } else {
            std.debug.print("could not solve\n", .{});
        }
    }

    fn solveNext(self: *Sudoku, x: u8, y: u8) bool {
        assert(0 <= x and x < GRID_SIZE);
        assert(0 <= y and y < GRID_SIZE);
        if (self.state[y][x].type == CellType.Fixed) {
            if (y == GRID_SIZE - 1 and x == GRID_SIZE - 1) {
                return true;
            }

            if (x < GRID_SIZE - 1) {
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
            for (0..MAX_CELL_VALUE) |possibleValue| {
                assert(MIN_CELL_VALUE <= (possibleValue + 1) and (possibleValue + 1) <= MAX_CELL_VALUE);
                if (self.isSafeValue(@as(u8, @intCast(possibleValue + 1)), x, y)) {
                    self.state[y][x].value = @as(u8, @intCast(possibleValue + 1));
                    if (y == GRID_SIZE - 1 and x == GRID_SIZE - 1) {
                        return true;
                    }
                    if (x < GRID_SIZE - 1) {
                        if (self.solveNext(x + 1, y)) {
                            return true;
                        }
                    } else {
                        if (self.solveNext(0, y + 1)) {
                            return true;
                        }
                    }
                }
                self.state[y][x].value = @as(u8, 0);
            }
            return false;
        }
    }

    pub fn isSolved(self: *Sudoku) bool {
        var arr: [MAX_CELL_VALUE]bool = undefined;
        // checks if all the blocks are valid
        for (0..BLOCK_COUNT_Y) |blockY| {
            for (0..BLOCK_COUNT_X) |blockX| {
                for (0..BLOCK_HEIGHT) |row| {
                    for (0..BLOCK_WIDTH) |col| {
                        if (self.state[(blockY * BLOCK_HEIGHT) + row][(blockX * BLOCK_WIDTH) + col].value == 0) {
                            return false;
                        }
                        arr[self.state[(blockY * BLOCK_HEIGHT) + row][(blockX * BLOCK_WIDTH) + col].value - 1] = true;
                    }
                }
                // checks if all the values are present
                for (arr) |value| {
                    if (value == false) {
                        return false;
                    }
                }
                // clears the arr to check the next block
                arr = std.mem.zeroes([MAX_CELL_VALUE]bool);
            }
        }
        // checks if all the rows are valid
        for (self.state) |row| {
            // clears the arr to check the next row
            arr = std.mem.zeroes([MAX_CELL_VALUE]bool);
            for (row) |cell| {
                assert(cell.value >= MIN_CELL_VALUE and cell.value <= MAX_CELL_VALUE);
                if (arr[cell.value - 1] == true) {
                    return false;
                }
                arr[cell.value - 1] = true;
            }
        }
        util.transpose(SudokuCell, &self.state);
        // checks if all the columns are valid
        for (self.state) |row| {
            // clears the arr to check the next column
            arr = std.mem.zeroes([MAX_CELL_VALUE]bool);
            for (row) |cell| {
                assert(cell.value >= MIN_CELL_VALUE and cell.value <= MAX_CELL_VALUE);
                if (arr[cell.value - 1] == true) {
                    return false;
                }
                arr[cell.value - 1] = true;
            }
        }
        // restores the game to its original state
        util.transpose(SudokuCell, &self.state);
        return true;
    }

    pub fn print(self: *const Sudoku) void {
        for (self.state) |row| {
            for (row) |cell| {
                std.debug.print("{any}, ", .{cell.value});
            }
            std.debug.print("\n", .{});
        }
    }
};

test "isSolved function for empty game" {
    var game = Sudoku{};
    _ = game.init();
    try expect(!game.isSolved());
}

test "solve function" {
    var game = Sudoku{ .state = [GRID_SIZE][GRID_SIZE]SudokuCell{
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 4, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 7, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 1, .type = CellType.Fixed } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 1, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 9, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 8, .type = CellType.Fixed }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 9, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 1, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 7, .type = CellType.Fixed }, SudokuCell{ .value = 4, .type = CellType.Fixed } },
        [GRID_SIZE]SudokuCell{ SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 5, .type = CellType.Fixed }, SudokuCell{ .value = 2, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 6, .type = CellType.Fixed }, SudokuCell{ .value = 3, .type = CellType.Fixed }, SudokuCell{ .value = 0, .type = CellType.Variable }, SudokuCell{ .value = 0, .type = CellType.Variable } },
    } };
    game.solve();
    try expect(game.isSolved());
}

test "generate function" {
    var game = Sudoku{ .difficulty = GameDifficulty.Hard };
    game.init();
    game.solve();
    try expect(game.isSolved());
}

test "game difficulty" {
    var game1 = Sudoku{ .difficulty = GameDifficulty.Hard };
    // HARD: util.Range{ .start = 17, .end = 21 };
    game1.init();
    var count: usize = 0;
    for (0..game1.state.len) |y| {
        for (0..game1.state[y].len) |x| {
            if (game1.state[y][x].value != 0) {
                count += 1;
            }
        }
    }
    try expect(17 <= count and count <= 21);
    var game2 = Sudoku{ .difficulty = GameDifficulty.Medium };
    // MEDIUM: util.Range{ .start = 21, .end = 32 };
    game2.init();
    count = 0;
    for (0..game2.state.len) |y| {
        for (0..game2.state[y].len) |x| {
            if (game2.state[y][x].value != 0) {
                count += 1;
            }
        }
    }
    try expect(21 <= count and count <= 32);
    var game3 = Sudoku{ .difficulty = GameDifficulty.Easy };
    // EASY: util.Range{ .start = 32, .end = 45 };
    game3.init();
    count = 0;
    for (0..game3.state.len) |y| {
        for (0..game3.state[y].len) |x| {
            if (game3.state[y][x].value != 0) {
                count += 1;
            }
        }
    }
    try expect(32 <= count and count <= 45);
}

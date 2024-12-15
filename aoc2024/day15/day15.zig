const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const Vec2 = struct { row: i32, col: i32 };

const Dir = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,

    fn to_vec(self: Dir) Vec2 {
        return switch (self) {
            .LEFT => Vec2{ .row = 0, .col = -1 },
            .RIGHT => Vec2{ .row = 0, .col = 1 },
            .UP => Vec2{ .row = -1, .col = 0 },
            .DOWN => Vec2{ .row = 1, .col = 0 },
        };
    }
};

const ALL_DIRS: [4]Dir = [4]Dir{
    .LEFT,
    .RIGHT,
    .UP,
    .DOWN,
};

fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        width: usize,
        height: usize,
        data: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !Self {
            var data = std.ArrayList(T).init(allocator);
            var lines = std.mem.split(u8, bytes, "\n");
            var row: usize = 0;
            var width: usize = 0;
            while (lines.next()) |line| {
                if (line.len == 0) break;
                for (0.., line) |col, c| {
                    try data.append(c);
                    width = @max(col, width);
                }
                row += 1;
            }

            return Self{ .width = width + 1, .height = row, .data = data };
        }

        pub fn at(self: *const Self, row: i32, col: i32) ?*T {
            if (row >= 0 and row < self.height and col >= 0 and col < self.width) {
                const width: i32 = @intCast(self.width);
                const idx: usize = @intCast(row * width + col);
                return &self.data.items[idx];
            } else {
                return null;
            }
        }

        pub fn at_vec2(self: *const Self, pos: Vec2) ?*T {
            return self.at(pos.row, pos.col);
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn in_bounds(self: *const Self, row: i32, col: i32) bool {
            return row >= 0 and row < self.height and col >= 0 and col < self.width;
        }
        pub fn set(self: *Self, pos: Vec2, value: T) bool {
            if (self.in_bounds(pos.row, pos.col)) {
                const width: i32 = @intCast(self.width);
                const idx: usize = @intCast(pos.row * width + pos.col);
                self.data.items[idx] = value;
                return true;
            }
            return false;
        }
    };
}

const Robot = struct {
    pos: Vec2,

    fn from_grid(grid: *const Grid(u8)) !Robot {
        for (0..grid.height) |row| {
            const row_i32: i32 = @as(i32, @intCast(row));
            for (0..grid.width) |col| {
                const col_i32: i32 = @as(i32, @intCast(col));
                if (grid.at(row_i32, col_i32).?.* == '@') {
                    return Robot{ .pos = Vec2{ .row = row_i32, .col = col_i32 } };
                }
            }
        }
        return error.RobotNotFound;
    }

    fn push(self: *Robot, grid: *Grid(u8), dir: Dir) bool {
        const dv = dir.to_vec();

        const next_pos = Vec2{ .row = self.pos.row + dv.row, .col = self.pos.col + dv.col };
        const next_cell = grid.at_vec2(next_pos);
        if (next_cell) |n| {
            switch (n.*) {
                '.', '@' => {
                    self.pos = next_pos;
                    return true;
                },
                'O' => {
                    // line scan
                    var tpos = next_pos;
                    while (grid.in_bounds(tpos.row, tpos.col)) {
                        if (grid.at_vec2(tpos)) |p| {
                            if (p.* == '.') {
                                _ = grid.set(tpos, 'O');
                                _ = grid.set(next_pos, '.');
                                self.pos = next_pos;
                                return true;
                            } else if (p.* == '#') {
                                return false;
                            }
                        }
                        tpos.row += dv.row;
                        tpos.col += dv.col;
                    }
                },
                else => {},
            }
        }
        return false;
    }
};

fn parse_instructions(allocator: std.mem.Allocator, bytes: []const u8) !std.ArrayList(Dir) {
    var instructions = std.ArrayList(Dir).init(allocator);
    for (bytes) |c| {
        if (c == '\n') continue;
        const dir: Dir = switch (c) {
            '<' => .LEFT,
            '^' => .UP,
            '>' => .RIGHT,
            'v' => .DOWN,
            else => unreachable,
        };
        try instructions.append(dir);
    }
    return instructions;
}

const Problem = struct {
    robot: Robot,
    instructions: std.ArrayList(Dir),
    grid: Grid(u8),

    fn from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Problem {
        var it = std.mem.splitSequence(u8, bytes, "\n\n");
        const grid = try Grid(u8).init(allocator, it.next().?);
        return Problem{
            .grid = grid,
            .robot = try Robot.from_grid(&grid),
            .instructions = try parse_instructions(allocator, it.next().?),
        };
    }

    fn deinit(self: *Problem) void {
        self.instructions.deinit();
        self.grid.deinit();
    }

    fn run(self: *Problem) void {
        for (self.instructions.items) |dir| {
            _ = self.robot.push(&self.grid, dir);
        }
    }

    fn compute_gps_sum(self: *const Problem) usize {
        var sum: usize = 0;
        for (0..self.grid.height) |row| {
            const row_i32: i32 = @as(i32, @intCast(row));
            for (0..self.grid.width) |col| {
                const col_i32: i32 = @as(i32, @intCast(col));
                if (self.grid.at(row_i32, col_i32).?.* == 'O') {
                    sum += 100 * row + col;
                }
            }
        }
        return sum;
    }

    pub fn display(self: *const Problem) void {
        for (0..self.grid.height) |row| {
            const row_i32: i32 = @as(i32, @intCast(row));
            for (0..self.grid.width) |col| {
                const col_i32: i32 = @as(i32, @intCast(col));
                const c = self.grid.at(row_i32, col_i32).?.*;
                if (row_i32 == self.robot.pos.row and col_i32 == self.robot.pos.col) {
                    print("@", .{});
                } else if (c == '@') {
                    print(".", .{});
                } else {
                    print("{c}", .{c});
                }
            }

            print("\n", .{});
        }
    }
};

fn read_file(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(
        filename,
        .{},
    );
    defer file.close();

    const stat = try file.stat();
    const buff = try file.readToEndAlloc(allocator, stat.size);
    return buff;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var problem = try Problem.from_bytes(allocator, buff);
    defer problem.deinit();

    problem.run();

    print("Part1: {}\n", .{problem.compute_gps_sum()});
}

const EXAMPLE =
    \\########
    \\#..O.O.#
    \\##@.O..#
    \\#...O..#
    \\#.#.O..#
    \\#...O..#
    \\#......#
    \\########
    \\
    \\<^^>>>vv<v>>v<<
;

const LARGE_EXAMPLE =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
;

test "problem setup" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();
    try testing.expectEqual(8, problem.grid.width);
    try testing.expectEqual(8, problem.grid.height);

    try testing.expectEqual(2, problem.robot.pos.col);
    try testing.expectEqual(2, problem.robot.pos.row);

    try testing.expectEqual(15, problem.instructions.items.len);
}

test "simple movement" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();

    try testing.expect(!problem.robot.push(&problem.grid, Dir.LEFT));
    try testing.expectEqual(2, problem.robot.pos.col);
    try testing.expectEqual(2, problem.robot.pos.row);

    try testing.expect(problem.robot.push(&problem.grid, Dir.RIGHT));
    try testing.expectEqual(3, problem.robot.pos.col);
    try testing.expectEqual(2, problem.robot.pos.row);

    try testing.expect(problem.robot.push(&problem.grid, Dir.DOWN));
    try testing.expectEqual(3, problem.robot.pos.col);
    try testing.expectEqual(3, problem.robot.pos.row);

    try testing.expect(problem.robot.push(&problem.grid, Dir.LEFT));
    try testing.expectEqual(2, problem.robot.pos.col);
    try testing.expectEqual(3, problem.robot.pos.row);

    try testing.expect(problem.robot.push(&problem.grid, Dir.LEFT));
    try testing.expectEqual(1, problem.robot.pos.col);
    try testing.expectEqual(3, problem.robot.pos.row);

    try testing.expect(!problem.robot.push(&problem.grid, Dir.LEFT));
    try testing.expectEqual(1, problem.robot.pos.col);
    try testing.expectEqual(3, problem.robot.pos.row);

    try testing.expect(!problem.robot.push(&problem.grid, Dir.LEFT));
    try testing.expectEqual(1, problem.robot.pos.col);
    try testing.expectEqual(3, problem.robot.pos.row);
}

test "pushing boxes" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();

    try testing.expect(problem.robot.push(&problem.grid, Dir.RIGHT)); // moves into empty
    try testing.expect(problem.robot.push(&problem.grid, Dir.RIGHT)); // pushes box
    try testing.expectEqual('.', problem.grid.at(2, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(2, 5).?.*);

    try testing.expect(problem.robot.push(&problem.grid, Dir.DOWN)); // pushes many boxes
    try testing.expectEqual('.', problem.grid.at(3, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(4, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(5, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(6, 4).?.*);

    try testing.expect(!problem.robot.push(&problem.grid, Dir.DOWN)); // not allowed
    try testing.expectEqual('O', problem.grid.at(4, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(5, 4).?.*);
    try testing.expectEqual('O', problem.grid.at(6, 4).?.*);
}

test "example" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();

    problem.run();
    try testing.expectEqual(2028, problem.compute_gps_sum());
    try testing.expectEqual(4, problem.robot.pos.row);
    try testing.expectEqual(4, problem.robot.pos.col);
}

test "large example" {
    var problem = try Problem.from_bytes(testing.allocator, LARGE_EXAMPLE);
    defer problem.deinit();

    problem.run();
    try testing.expectEqual(10092, problem.compute_gps_sum());
    try testing.expectEqual(4, problem.robot.pos.row);
    try testing.expectEqual(3, problem.robot.pos.col);
}

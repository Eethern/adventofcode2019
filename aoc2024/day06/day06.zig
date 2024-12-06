const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const testing = std.testing;

const Turn = enum { CLOCKWISE, COUNTER_CLOCKWISE };

const Vec2 = struct {
    x: i32,
    y: i32,
};

const Grid = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(u8),
    robot_spawn: Vec2,

    pub fn init_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Grid {
        var data = std.ArrayList(u8).init(allocator);
        var row: usize = 0;
        var width: usize = 0;
        var robot_pos = Vec2{ .x = 0, .y = 0 };

        var lines = std.mem.split(u8, bytes, "\n");
        while (lines.next()) |line| {
            for (0.., line) |col, c| {
                try data.append(c);
                width = @max(col, width);

                if (c == '^') {
                    robot_pos.x = @intCast(col);
                    robot_pos.y = @intCast(row);
                }
            }
            row += 1;
        }

        return Grid{ .width = width + 1, .height = row, .data = data, .robot_spawn = robot_pos };
    }

    pub fn init_empty(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
        var data = try std.ArrayList(u8).initCapacity(allocator, width * height);
        data.appendNTimesAssumeCapacity(0, width * height);
        return Grid{ .width = width, .height = height, .data = data, .robot_spawn = Vec2{ .x = 0, .y = 0 } };
    }

    pub fn deinit(self: *Grid) void {
        self.data.deinit();
    }

    pub fn at(self: *const Grid, row: i32, col: i32) ?u8 {
        if (self.in_bounds(row, col)) {
            const width: i32 = @intCast(self.width);
            const idx: usize = @intCast(row * width + col);
            return self.data.items[idx];
        } else {
            return null;
        }
    }

    pub fn set(self: *const Grid, row: i32, col: i32, value: u8) void {
        const width: i32 = @intCast(self.width);
        const idx: usize = @intCast(row * width + col);
        self.data.items[idx] = value;
    }

    pub fn in_bounds(self: *const Grid, row: i32, col: i32) bool {
        return row >= 0 and row < self.height and col >= 0 and col < self.width;
    }
};

const Robot = struct {
    pos: Vec2,
    orient: Vec2,

    pub fn patrol(self: *Robot, grid: *Grid, visited_grid: *Grid) void {
        self.pos.x = grid.robot_spawn.x;
        self.pos.y = grid.robot_spawn.y;

        while (grid.in_bounds(self.pos.y, self.pos.x)) {
            visited_grid.set(self.pos.y, self.pos.x, visited_grid.at(self.pos.y, self.pos.x).? + 1);
            self.forward();
            if (self.peek(grid) == '#') {
                self.turn(Turn.COUNTER_CLOCKWISE);
            }
        }
    }

    pub fn peek(self: *Robot, grid: *Grid) ?u8 {
        return grid.at(self.pos.y + self.orient.y, self.pos.x + self.orient.x);
    }

    pub fn forward(self: *Robot) void {
        self.pos.x += self.orient.x;
        self.pos.y += self.orient.y;
    }

    pub fn turn(self: *Robot, t: Turn) void {
        self.orient = switch (t) {
            .CLOCKWISE => Vec2{ .x = self.orient.y, .y = -self.orient.x },
            .COUNTER_CLOCKWISE => Vec2{ .x = -self.orient.y, .y = self.orient.x },
        };
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

pub fn count_visited_cells(grid: *const Grid) usize {
    var unique_cells: usize = 0;
    for (grid.data.items) |num_visited| {
        if (num_visited > 0) {
            unique_cells += 1;
        }
    }
    return unique_cells;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const grid_bytes = try read_file(allocator, "input.txt");
    defer allocator.free(grid_bytes);

    var grid = try Grid.init_from_bytes(allocator, grid_bytes);
    defer grid.deinit();

    var visited_grid = try Grid.init_empty(allocator, grid.width, grid.height);
    defer visited_grid.deinit();

    var robot = Robot{ .pos = Vec2{ .x = 0, .y = 0 }, .orient = Vec2{ .x = 0, .y = -1 } };
    robot.patrol(&grid, &visited_grid);

    const unique_cells = count_visited_cells(&visited_grid);
    print("Part 1: {}\n", .{unique_cells});
}

test "grid" {
    const grid_bytes =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    var grid = try Grid.init_from_bytes(testing.allocator, grid_bytes);
    defer grid.deinit();

    try testing.expectEqual(4, grid.robot_spawn.x);
    try testing.expectEqual(6, grid.robot_spawn.y);

    try testing.expectEqual(10, grid.height);
    try testing.expectEqual(10, grid.width);

    try testing.expectEqual('#', grid.at(3, 2).?);
    try testing.expectEqual('.', grid.at(1, 1).?);
}

test "robot_move" {
    var robot = Robot{ .pos = Vec2{ .x = 0, .y = 0 }, .orient = Vec2{ .x = 0, .y = 1 } };
    robot.forward();
    try testing.expectEqual(robot.pos.x, 0);
    try testing.expectEqual(robot.pos.y, 1);
}

test "robot_turn_clockwise" {
    var robot = Robot{ .pos = Vec2{ .x = 0, .y = 0 }, .orient = Vec2{ .x = 0, .y = 1 } };
    robot.turn(Turn.CLOCKWISE);
    try testing.expectEqual(1, robot.orient.x);
    try testing.expectEqual(0, robot.orient.y);
}

test "robot_turn_counter_clockwise" {
    var robot = Robot{ .pos = Vec2{ .x = 0, .y = 0 }, .orient = Vec2{ .x = 0, .y = 1 } };
    robot.turn(Turn.COUNTER_CLOCKWISE);
    try testing.expectEqual(-1, robot.orient.x);
    try testing.expectEqual(0, robot.orient.y);
}

test "robot_patrol" {
    const grid_bytes =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    var grid = try Grid.init_from_bytes(testing.allocator, grid_bytes);
    defer grid.deinit();
    var visited_grid = try Grid.init_empty(testing.allocator, grid.width, grid.height);
    defer visited_grid.deinit();
    var robot = Robot{ .pos = Vec2{ .x = 0, .y = 0 }, .orient = Vec2{ .x = 0, .y = -1 } };
    robot.patrol(&grid, &visited_grid);
    try testing.expectEqual(7, robot.pos.x);
    try testing.expectEqual(10, robot.pos.y);

    const unique_cells = count_visited_cells(&visited_grid);
    try testing.expectEqual(41, unique_cells);
}

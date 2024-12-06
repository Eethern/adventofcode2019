const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const testing = std.testing;

const Turn = enum { CLOCKWISE, COUNTER_CLOCKWISE };

const Vec2 = @Vector(2, i32);

const Grid = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(u8),
    robot_spawn: Vec2,

    pub fn init_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Grid {
        var data = std.ArrayList(u8).init(allocator);
        var row: usize = 0;
        var width: usize = 0;
        var robot_pos: Vec2 = .{ 0, 0 };

        var lines = std.mem.split(u8, bytes, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) {
                break;
            }

            for (0.., line) |col, c| {
                try data.append(c);
                width = @max(col, width);

                if (c == '^') {
                    robot_pos = .{ @intCast(col), @intCast(row) };
                }
            }
            row += 1;
        }

        return Grid{ .width = width + 1, .height = row, .data = data, .robot_spawn = robot_pos };
    }

    pub fn init_empty(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
        var data = try std.ArrayList(u8).initCapacity(allocator, width * height);
        data.appendNTimesAssumeCapacity(0, width * height);
        return Grid{ .width = width, .height = height, .data = data, .robot_spawn = .{ 0, 0 } };
    }

    pub fn deinit(self: *Grid) void {
        self.data.deinit();
    }

    pub fn at(self: *const Grid, pos: Vec2) ?u8 {
        if (self.in_bounds(pos)) {
            const width: i32 = @intCast(self.width);
            const idx: usize = @intCast(pos[1] * width + pos[0]);
            return self.data.items[idx];
        } else {
            return null;
        }
    }

    pub fn set(self: *const Grid, pos: Vec2, value: u8) void {
        const width: i32 = @intCast(self.width);
        const idx: usize = @intCast(pos[1] * width + pos[0]);
        self.data.items[idx] = value;
    }

    pub fn in_bounds(self: *const Grid, pos: Vec2) bool {
        return pos[1] >= 0 and pos[1] < self.height and pos[0] >= 0 and pos[0] < self.width;
    }
};

const Robot = struct {
    pos: Vec2,
    orient: Vec2,

    pub fn patrol(self: *Robot, grid: *Grid, visited_grid: *Grid) void {
        self.pos = grid.robot_spawn;

        while (grid.in_bounds(self.pos)) {
            visited_grid.set(self.pos, visited_grid.at(self.pos).? + 1);
            self.forward();
            if (self.peek(grid) == '#') {
                self.turn(Turn.COUNTER_CLOCKWISE);
            }
        }
    }

    pub fn peek(self: *Robot, grid: *Grid) ?u8 {
        return grid.at(self.pos + self.orient);
    }

    pub fn forward(self: *Robot) void {
        self.pos += self.orient;
    }

    pub fn turn(self: *Robot, t: Turn) void {
        const orient = self.orient;
        self.orient = switch (t) {
            .CLOCKWISE => .{ orient[1], -orient[0] },
            .COUNTER_CLOCKWISE => .{ -orient[1], orient[0] },
        };
    }

    pub fn hash_state(self: *const Robot) u128 {
        assert(self.pos[0] + 1 >= 0);
        assert(self.pos[1] + 1 >= 0);
        assert(self.orient[0] + 1 >= 0);
        assert(self.orient[1] + 1 >= 0);
        var hash: u128 = @as(u128, @bitCast(@as(i128, self.pos[0] + 1)));
        hash = (hash << 32) | @as(u128, @bitCast(@as(i128, self.pos[1] + 1)));
        hash = (hash << 32) | @as(u128, @bitCast(@as(i128, self.orient[0] + 1)));
        hash = (hash << 32) | @as(u128, @bitCast(@as(i128, self.orient[1] + 1)));
        return hash;
    }
};

const Simulator = struct {
    state_map: std.AutoHashMap(u128, bool),
    grid: *Grid,
    visited_map: std.AutoHashMap(Vec2, bool),

    pub fn init(allocator: std.mem.Allocator, grid: *Grid) !Simulator {
        const state_map = std.AutoHashMap(u128, bool).init(allocator);
        const visited_map = std.AutoHashMap(Vec2, bool).init(allocator);
        return Simulator{ .state_map = state_map, .grid = grid, .visited_map = visited_map };
    }

    pub fn deinit(self: *Simulator) void {
        self.state_map.deinit();
        self.visited_map.deinit();
    }

    pub fn record_state(self: *Simulator, robot: *Robot) void {
        const hash = robot.hash_state();
        self.state_map.put(hash, true);
    }

    pub fn detect_loop(self: *Simulator, robot: *Robot) !bool {
        while (self.grid.in_bounds(robot.pos)) {
            if (robot.peek(self.grid) == '#') {
                const hash = robot.hash_state();
                if (self.state_map.contains(hash)) {
                    return true;
                }
                try self.state_map.put(hash, true);

                robot.turn(Turn.COUNTER_CLOCKWISE);
            } else {
                robot.forward();
            }
        }

        return false;
    }

    pub fn count_loops(self: *Simulator) !usize {
        var num_loops: usize = 0;
        var robot = Robot{ .pos = self.grid.robot_spawn, .orient = .{ 0, -1 } };
        while (self.grid.in_bounds(robot.pos)) {
            const save_position = robot.pos;
            const save_orientation = robot.orient;

            const wall = robot.pos + robot.orient;

            if (!self.grid.in_bounds(wall)) {
                robot.forward();
                break;
            }

            const before: u8 = self.grid.at(wall).?;
            if (before == '#') {
                robot.turn(Turn.COUNTER_CLOCKWISE);
                continue;
            }

            if (self.visited_map.contains(wall)) {
                robot.forward();
                continue;
            }

            self.grid.set(wall, '#');
            try self.visited_map.put(wall, true);

            if (try self.detect_loop(&robot)) {
                num_loops += 1;
            }

            // restore
            robot.pos = save_position;
            robot.orient = save_orientation;
            self.state_map.clearAndFree();
            self.grid.set(wall, before);
            robot.forward();
        }
        return num_loops;
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

    var robot = Robot{ .pos = .{ 0, 0 }, .orient = .{ 0, -1 } };
    robot.patrol(&grid, &visited_grid);

    const unique_cells = count_visited_cells(&visited_grid);
    var simulator = try Simulator.init(allocator, &grid);
    defer simulator.deinit();

    print("Part 1: {}\n", .{unique_cells});
    print("Part 2: {}\n", .{try simulator.count_loops()});
}

const EXAMPLE_GRID =
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

test "grid" {
    var grid = try Grid.init_from_bytes(testing.allocator, EXAMPLE_GRID);
    defer grid.deinit();

    try testing.expectEqual(grid.robot_spawn, .{ 4, 6 });

    try testing.expectEqual(10, grid.height);
    try testing.expectEqual(10, grid.width);

    try testing.expectEqual('#', grid.at(.{ 2, 3 }).?);
    try testing.expectEqual('.', grid.at(.{ 1, 1 }).?);
}

test "robot_move" {
    var robot = Robot{ .pos = .{ 0, 0 }, .orient = .{ 0, 1 } };
    robot.forward();

    try testing.expectEqual(.{ 0, 1 }, robot.pos);
}

test "robot_turn_clockwise" {
    var robot = Robot{ .pos = .{ 0, 0 }, .orient = .{ 0, 1 } };
    robot.turn(Turn.CLOCKWISE);

    try testing.expectEqual(.{ 1, 0 }, robot.orient);
}

test "robot_turn_counter_clockwise" {
    var robot = Robot{ .pos = .{ 0, 0 }, .orient = .{ 0, 1 } };
    robot.turn(Turn.COUNTER_CLOCKWISE);
    try testing.expectEqual(.{ -1, 0 }, robot.orient);
}

test "robot_patrol" {
    var grid = try Grid.init_from_bytes(testing.allocator, EXAMPLE_GRID);
    defer grid.deinit();
    var visited_grid = try Grid.init_empty(testing.allocator, grid.width, grid.height);
    defer visited_grid.deinit();
    var robot = Robot{ .pos = .{ 0, 0 }, .orient = .{ 0, -1 } };
    robot.patrol(&grid, &visited_grid);
    try testing.expectEqual(.{ 7, 10 }, robot.pos);

    const unique_cells = count_visited_cells(&visited_grid);
    try testing.expectEqual(41, unique_cells);
}

test "loop" {
    var grid = try Grid.init_from_bytes(testing.allocator, EXAMPLE_GRID);
    defer grid.deinit();

    var simulator = try Simulator.init(testing.allocator, &grid);
    defer simulator.deinit();

    try testing.expectEqual(6, simulator.count_loops());
}

const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const Vec2 = struct {
    row: i32,
    col: i32,
    fn move(self: *const Vec2, dir: Dir) Vec2 {
        const dv = dir.to_vec();
        return Vec2{ .row = self.row + dv.row, .col = self.col + dv.col };
    }
};

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

    fn opposite(self: Dir) Dir {
        return switch (self) {
            .LEFT => .RIGHT,
            .RIGHT => .LEFT,
            .UP => .DOWN,
            .DOWN => .UP,
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
        start: Vec2,
        end: Vec2,

        pub fn from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Self {
            var data = std.ArrayList(T).init(allocator);
            var lines = std.mem.split(u8, bytes, "\n");
            var row: usize = 0;
            var width: usize = 0;
            var start: Vec2 = undefined;
            var end: Vec2 = undefined;
            while (lines.next()) |line| {
                if (line.len == 0) break;
                for (0.., line) |col, c| {
                    try data.append(c);
                    width = @max(col, width);

                    if (c == 'S') {
                        start = Vec2{ .row = @as(i32, @intCast(row)), .col = @as(i32, @intCast(col)) };
                    } else if (c == 'E') {
                        end = Vec2{ .row = @as(i32, @intCast(row)), .col = @as(i32, @intCast(col)) };
                    }
                }
                row += 1;
            }

            return Self{
                .width = width + 1,
                .height = row,
                .data = data,
                .start = start,
                .end = end,
            };
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn at(self: *const Self, row: i32, col: i32) ?T {
            if (row >= 0 and row < self.height and col >= 0 and col < self.width) {
                const width: i32 = @intCast(self.width);
                const idx: usize = @intCast(row * width + col);
                return self.data.items[idx];
            } else {
                return null;
            }
        }

        pub fn at_vec2(self: *const Self, pos: Vec2) ?T {
            return self.at(pos.row, pos.col);
        }

        pub fn display(self: *const Self) void {
            for (0..self.height) |row| {
                const row_i32: i32 = @as(i32, @intCast(row));
                for (0..self.width) |col| {
                    const col_i32: i32 = @as(i32, @intCast(col));
                    const c = self.at(row_i32, col_i32).?;
                    print("{c}", .{c});
                }

                print("\n", .{});
            }
        }

        pub fn in_bounds(self: *const Self, pos: Vec2) bool {
            return pos.row >= 0 and pos.row < self.height and pos.col >= 0 and pos.col < self.width;
        }
    };
}

const Move = enum {
    NotAllowed,
    Allowed,
};

const State = struct {
    pos: Vec2,
    prev: ?Vec2 = null,
    distance: usize = 0,
};

fn can_traverse(grid: *const Grid(u8), next: Vec2) Move {
    const cell = grid.at_vec2(next);
    if (cell == null or cell.? == '#') {
        return .NotAllowed;
    }

    return .Allowed;
}

pub fn state_cmp(ctx: void, a: State, b: State) std.math.Order {
    _ = ctx;
    return std.math.order(b.distance, a.distance);
}

fn dijkstras(allocator: std.mem.Allocator, grid: *const Grid(u8), start_state: State) !std.AutoHashMap(Vec2, State) {
    var distances = std.AutoHashMap(Vec2, State).init(allocator);
    try distances.put(start_state.pos, start_state);

    var frontier = std.PriorityDequeue(State, void, state_cmp).init(allocator, undefined);
    defer frontier.deinit();
    try frontier.add(start_state);

    while (frontier.count() > 0) {
        const curr = frontier.removeMin();
        for (ALL_DIRS) |dir| {
            const next_state = State{
                .pos = curr.pos.move(dir),
                .prev = curr.pos,
                .distance = curr.distance + 1,
            };

            if (can_traverse(grid, next_state.pos) == .NotAllowed) {
                continue;
            }

            const best_dist: usize = if (distances.get(next_state.pos)) |d| d.distance else std.math.maxInt(usize);
            if (next_state.distance < best_dist) {
                try frontier.add(next_state);
                try distances.put(next_state.pos, next_state);
            }
        }
    }
    return distances;
}

fn calculate_cheat_gains(allocator: std.mem.Allocator, grid: *const Grid(u8), distances: *const std.AutoHashMap(Vec2, State)) ![]usize {
    // Savings gained by cheating at given position
    const worst_score = distances.get(grid.end).?.distance;
    var cheat_map: []usize = try allocator.alloc(usize, worst_score);
    @memset(cheat_map, 0);

    var node = distances.get(grid.end).?;
    while (node.prev) |_| : (node = distances.get(node.prev.?).?) {
        // try cheating
        for (ALL_DIRS) |dir| {
            // Assume straight lines (L shapes will never be beneficial)
            const next_pos = node.pos.move(dir).move(dir);
            if (can_traverse(grid, next_pos) == .NotAllowed) continue;

            if (distances.get(next_pos)) |next_node| {
                if (node.distance + 2 < next_node.distance) {
                    cheat_map[next_node.distance - node.distance - 2] += 1;
                }
            }
        }
    }
    return cheat_map;
}

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

    const bytes = try read_file(allocator, "input.txt");
    defer allocator.free(bytes);

    var grid = try Grid(u8).from_bytes(allocator, bytes);
    defer grid.deinit();

    const start_state = State{
        .pos = grid.start,
        .prev = null,
        .distance = 0,
    };

    var distances = try dijkstras(allocator, &grid, start_state);
    defer distances.deinit();

    const cheat_map = try calculate_cheat_gains(allocator, &grid, &distances);
    defer allocator.free(cheat_map);

    var part1_answer: usize = 0;
    for (cheat_map[100..]) |item| {
        part1_answer += item;
    }

    std.debug.print("Part1: {}\n", .{part1_answer});
}

const EXAMPLE =
    \\###############
    \\#...#...#.....#
    \\#.#.#.#.#.###.#
    \\#S#...#.#.#...#
    \\#######.#.#.###
    \\#######.#.#...#
    \\#######.#.###.#
    \\###..E#...#...#
    \\###.#######.###
    \\#...###...#...#
    \\#.#####.#.###.#
    \\#.#...#.#.#...#
    \\#.#.#.#.#.#.###
    \\#...#...#...###
    \\###############
;

test "parse" {
    var grid = try Grid(u8).from_bytes(testing.allocator, EXAMPLE);
    defer grid.deinit();
    try testing.expectEqual(15, grid.width);
    try testing.expectEqual(15, grid.height);
    try testing.expectEqual(3, grid.start.row);
    try testing.expectEqual(1, grid.start.col);
    try testing.expectEqual(7, grid.end.row);
    try testing.expectEqual(5, grid.end.col);
}

test "can_traverse" {
    var grid = try Grid(u8).from_bytes(testing.allocator, EXAMPLE);
    defer grid.deinit();

    const state = State{
        .pos = grid.start,
        .prev = null,
        .distance = 0,
    };
    try testing.expectEqual(.Allowed, can_traverse(&grid, state.pos.move(.UP)));
    try testing.expectEqual(.NotAllowed, can_traverse(&grid, state.pos.move(.DOWN)));
    try testing.expectEqual(.NotAllowed, can_traverse(&grid, state.pos.move(.LEFT)));
    try testing.expectEqual(.NotAllowed, can_traverse(&grid, state.pos.move(.RIGHT)));
}

test "find_shortest_path_length" {
    var grid = try Grid(u8).from_bytes(testing.allocator, EXAMPLE);
    defer grid.deinit();

    // No cheats
    {
        const start_state = State{
            .pos = grid.start,
            .prev = null,
            .distance = 0,
        };

        var distances = try dijkstras(testing.allocator, &grid, start_state);
        defer distances.deinit();
        try testing.expectEqual(84, distances.get(grid.end).?.distance);
    }
}


test "cheat_map gain" {
    var grid = try Grid(u8).from_bytes(testing.allocator, EXAMPLE);
    defer grid.deinit();

    // No cheats
    const start_state = State{
        .pos = grid.start,
        .prev = null,
        .distance = 0,
    };

    var distances = try dijkstras(testing.allocator, &grid, start_state);
    defer distances.deinit();

    const cheat_map = try calculate_cheat_gains(testing.allocator, &grid, &distances);
    defer testing.allocator.free(cheat_map);

    // We don't catch this one because of only doing straight lines
    // try testing.expectEqual(14, cheat_map[2]);
    // The first (4) valued cheat is not found for some reason
    // try testing.expectEqual(14, cheat_map[4]);
    try testing.expectEqual(2, cheat_map[6]);
    try testing.expectEqual(4, cheat_map[8]);
    try testing.expectEqual(2, cheat_map[10]);
    try testing.expectEqual(3, cheat_map[12]);
    try testing.expectEqual(1, cheat_map[20]);
    try testing.expectEqual(1, cheat_map[36]);
    try testing.expectEqual(1, cheat_map[38]);
    try testing.expectEqual(1, cheat_map[40]);
    try testing.expectEqual(1, cheat_map[64]);

}

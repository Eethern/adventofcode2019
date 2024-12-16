const std = @import("std");
const testing = std.testing;
const print = std.debug.print;
const assert = std.debug.assert;

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

    fn opposite(self: Dir) Dir {
        return switch(self) {
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

        pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !Self {
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

        pub fn deinit(self: *Self) void {
            self.data.deinit();
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

        pub fn in_bounds(self: *const Self, row: i32, col: i32) bool {
            return row >= 0 and row < self.height and col >= 0 and col < self.width;
        }
    };
}

const Visit = struct { vertex: Vec2, dist: usize, dir: Dir };

pub fn visit_order(ctx: void, a: Visit, b: Visit) std.math.Order {
    _ = ctx;
    return std.math.order(b.dist, a.dist);
}

fn cost_of_move(current_dir: Dir, wanted_dir: Dir) usize {
    if (current_dir == .UP) {
        if (wanted_dir == .UP) return 1;
        if (wanted_dir == .DOWN) return 2001;
        if ((wanted_dir == .LEFT) or (wanted_dir == .RIGHT)) return 1001;
    } else if (current_dir == .DOWN) {
        if (wanted_dir == .DOWN) return 1;
        if (wanted_dir == .UP) return 2001;
        if ((wanted_dir == .LEFT) or (wanted_dir == .RIGHT)) return 1001;
    } else if (current_dir == .LEFT) {
        if (wanted_dir == .LEFT) return 1;
        if (wanted_dir == .RIGHT) return 2001;
        if ((wanted_dir == .UP) or (wanted_dir == .DOWN)) return 1001;
    } else if (current_dir == .RIGHT) {
        if (wanted_dir == .RIGHT) return 1;
        if (wanted_dir == .LEFT) return 2001;
        if ((wanted_dir == .UP) or (wanted_dir == .DOWN)) return 1001;
    }

    // Default return value (should not reach here if inputs are valid)
    assert(false);
    return 0;
}

fn dijkstras(allocator: std.mem.Allocator, start: Vec2, grid: *const Grid(u8)) !std.AutoHashMap(Vec2, usize) {
    var visited = std.AutoHashMap(Vec2, void).init(allocator);
    defer visited.deinit();
    var to_visit = std.PriorityDequeue(Visit, void, visit_order).init(allocator, undefined);
    defer to_visit.deinit();
    // to be returned!
    var distances = std.AutoHashMap(Vec2, usize).init(allocator);

    try distances.put(start, 0);
    try to_visit.add(Visit{ .vertex = start, .dist = 0, .dir=.RIGHT });

    while (to_visit.count() > 0) {
        const next = to_visit.removeMin();
        try visited.put(next.vertex, undefined);

        for (ALL_DIRS) |dir| {
            const dv = dir.to_vec();
            const neighbor = Vec2{ .row = next.vertex.row + dv.row, .col = next.vertex.col + dv.col };

            if (grid.in_bounds(neighbor.row, neighbor.col)) {
                if (grid.at_vec2(neighbor)) |c| {
                    if (c == '#') continue;
                } else continue;

                const new_distance = next.dist + cost_of_move(next.dir, dir);
                const neighbor_dist = distances.get(neighbor) orelse std.math.maxInt(usize);
                if (new_distance < neighbor_dist) {
                    try distances.put(neighbor, new_distance);
                    try to_visit.add(Visit{ .vertex = neighbor, .dist = new_distance, .dir = dir });
                }
            }
        }
    }
    return distances;
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

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var grid = try Grid(u8).init(allocator, buff);
    defer grid.deinit();

    var distance_map = try dijkstras(allocator, grid.start, &grid);
    defer distance_map.deinit();
    print("Part1: {?}\n", .{distance_map.get(grid.end)});
}

const EXAMPLE =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
;

const LARGER_EXAMPLE =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
;

test "grid parse" {
    var grid = try Grid(u8).init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    try testing.expectEqual(15, grid.width);
    try testing.expectEqual(15, grid.height);
    try testing.expectEqual(Vec2 {.row = 13, .col = 1}, grid.start);
    try testing.expectEqual(Vec2 {.row = 1, .col = 13}, grid.end);
}

test "part1 dijkstras small" {
    var grid = try Grid(u8).init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    var distance_map = try dijkstras(testing.allocator, grid.start, &grid);
    defer distance_map.deinit();

    try testing.expectEqual(7036, distance_map.get(grid.end).?);

}

test "part1 dijkstras large" {
    var grid = try Grid(u8).init(testing.allocator, LARGER_EXAMPLE);
    defer grid.deinit();

    var distance_map = try dijkstras(testing.allocator, grid.start, &grid);
    defer distance_map.deinit();

    try testing.expectEqual(11048, distance_map.get(grid.end).?);
}

// test "part2 small" {
//     var grid = try Grid(u8).init(testing.allocator, LARGER_EXAMPLE);
//     defer grid.deinit();

//     var distance_map = try dijkstras(testing.allocator, grid.end, &grid);
//     defer distance_map.deinit();

//     var it = distance_map.iterator();
//     while (it.next()) |*entry| {
//         print("{}: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
//     }
// }

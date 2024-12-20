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

const Cell = struct {
    value: u8,
    time: usize,
};

fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        width: usize,
        height: usize,
        data: std.ArrayList(T),
        max_time: usize,

        pub fn from_bytes(allocator: std.mem.Allocator, bytes: []const u8, width: usize, height: usize) !Self {
            var data = std.ArrayList(T).init(allocator);
            try data.appendNTimes(Cell{ .value = '.', .time = std.math.maxInt(usize) }, width * height);
            var lines = std.mem.splitAny(u8, bytes, "\n");
            var time: usize = 0;
            while (lines.next()) |line| : (time += 1) {
                if (line.len == 0) continue;
                var it = std.mem.splitScalar(u8, line, ',');
                const x = try std.fmt.parseInt(usize, it.next().?, 10);
                const y = try std.fmt.parseInt(usize, it.next().?, 10);
                const idx = y * width + x;
                data.items[idx] = Cell{ .value = '#', .time = time };
            }

            return Self{
                .width = width,
                .height = height,
                .data = data,
                .max_time = time,
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
                    if (c.value == '#') {
                        print("{:2}", .{c.time});
                    } else {
                        print("[]", .{});
                    }
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
    return std.math.order(a.dist, b.dist);
}

fn dijkstras(allocator: std.mem.Allocator, start: Vec2, end: Vec2, grid: *const Grid(Cell), max_time: usize, part2: bool) !?usize {
    var frontier = std.PriorityDequeue(Visit, void, visit_order).init(allocator, undefined);
    defer frontier.deinit();
    // to be returned!
    var distances = std.AutoHashMap(Vec2, usize).init(allocator);
    defer distances.deinit();

    try distances.put(start, 0);
    try frontier.add(Visit{ .vertex = start, .dist = 0, .dir = .RIGHT });

    while (frontier.count() > 0) {
        const next = frontier.removeMin();

        for (ALL_DIRS) |dir| {
            const dv = dir.to_vec();
            const neighbor = Vec2{ .row = next.vertex.row + dv.row, .col = next.vertex.col + dv.col };

            if (grid.in_bounds(neighbor.row, neighbor.col)) {
                const new_distance = next.dist + 1;
                if (grid.at_vec2(neighbor)) |c| {
                    if (part2) {
                        if (c.value == '#' and c.time < max_time) continue;
                    } else {
                        if (c.value == '#' and (new_distance > c.time or c.time < max_time)) continue;
                    }
                } else continue;

                const neighbor_dist = distances.get(neighbor) orelse std.math.maxInt(usize);
                if (new_distance < neighbor_dist) {
                    try distances.put(neighbor, new_distance);
                    try frontier.add(Visit{ .vertex = neighbor, .dist = new_distance, .dir = dir });
                }
            }
        }
    }
    return distances.get(end);
}

fn find_first_problematic_byte(allocator: std.mem.Allocator, grid: *const Grid(Cell), end: Vec2) !usize {
    var t: usize = 0;
    while (t < grid.max_time) : (t += 1) {
        const result = try dijkstras(allocator, Vec2{ .row = 0, .col = 0 }, end, grid, t, true);
        if (result == null) {
            break;
        }
    }
    return t;
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

fn get_coordinate(bytes: []const u8, time: usize) ?[]const u8 {
    var line_it = std.mem.splitScalar(u8, bytes, '\n');
    var t: usize = 0;
    while (line_it.next()) |line| : (t += 1) {
        if (t + 1 == time) {
            return line;
        }
    }

    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var grid = try Grid(Cell).from_bytes(allocator, buff, 71, 71);
    defer grid.deinit();

    {
        const part1_answer = try dijkstras(allocator, Vec2{ .row = 0, .col = 0 }, Vec2{ .row = 70, .col = 70 }, &grid, 1024, false);
        print("Part1: {}\n", .{part1_answer.?});
    }

    const t: usize = try find_first_problematic_byte(allocator, &grid, Vec2{ .row = 70, .col = 70 });
    const part2_answer = get_coordinate(buff, t).?;
    print("Part2: {s}\n", .{part2_answer});
}

const EXAMPLE =
    \\5,4
    \\4,2
    \\4,5
    \\3,0
    \\2,1
    \\6,3
    \\2,4
    \\1,5
    \\0,6
    \\3,3
    \\2,6
    \\5,1
    \\1,2
    \\5,5
    \\2,5
    \\6,5
    \\1,4
    \\0,4
    \\6,4
    \\1,1
    \\6,1
    \\1,0
    \\0,5
    \\1,6
    \\2,0
;

test "grid parse" {
    var grid = try Grid(Cell).from_bytes(testing.allocator, EXAMPLE, 7, 7);
    defer grid.deinit();

    try testing.expectEqual(7, grid.width);
    try testing.expectEqual(7, grid.height);

    try testing.expectEqual('#', grid.at(0, 2).?.value);
    try testing.expectEqual('#', grid.at(4, 5).?.value);
    try testing.expectEqual('.', grid.at(0, 0).?.value);
    try testing.expectEqual('.', grid.at(6, 6).?.value);
    try testing.expectEqual(null, grid.at(7, 7));
}

test "dijkstras" {
    var grid = try Grid(Cell).from_bytes(testing.allocator, EXAMPLE, 7, 7);
    defer grid.deinit();

    const num_steps = try dijkstras(testing.allocator, Vec2{ .row = 0, .col = 0 }, Vec2{ .row = 6, .col = 6 }, &grid, 12, false);
    try testing.expectEqual(22, num_steps);

    const t: usize = try find_first_problematic_byte(testing.allocator, &grid, Vec2{ .row = 6, .col = 6 });
    try testing.expectEqual(21, t);
    const coordinate = get_coordinate(EXAMPLE, t).?;
    try testing.expectEqualStrings("6,1", coordinate);
}

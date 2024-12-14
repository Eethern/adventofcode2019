const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const Node = struct {
    row: i32,
    col: i32,
    value: usize,
};

const Vec2 = struct {
    row: i32,
    col: i32,
};

fn from_char(c: u8) u32 {
    return @as(u32, @intCast(c)) - @as(u32, @intCast('0'));
}

const Grid = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(?u32),

    pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !Grid {
        var data = std.ArrayList(?u32).init(allocator);
        var lines = std.mem.split(u8, bytes, "\n");
        var row: usize = 0;
        var width: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) break;
            for (0.., line) |col, c| {
                if (c == '.') {
                    try data.append(null);
                } else {
                    try data.append(from_char(c));
                }
                width = @max(col, width);
            }
            row += 1;
        }

        return Grid{ .width = width + 1, .height = row, .data = data };
    }

    pub fn deinit(self: *Grid) void {
        self.data.deinit();
    }

    pub fn at(self: *const Grid, row: i32, col: i32) ?u32 {
        if (row >= 0 and row < self.height and col >= 0 and col < self.width) {
            const width: i32 = @intCast(self.width);
            const idx: usize = @intCast(row * width + col);
            return self.data.items[idx];
        } else {
            return null;
        }
    }

    pub fn in_bounds(self: *const Grid, row: i32, col: i32) bool {
        return row >= 0 and row < self.height and col >= 0 and col < self.width;
    }
};

fn is_edge(visited: *const std.AutoHashMap(Vec2, void), grid: *const Grid, row: i32, col: i32, current_height: usize) bool {
    return !visited.contains(Vec2{ .col = col, .row = row }) and grid.in_bounds(row, col) and grid.at(row, col).? == current_height + 1;
}

fn dfs_find_end_points(allocator: std.mem.Allocator, grid: *const Grid, start_col: i32, start_row: i32) !usize {
    var visited = std.AutoHashMap(Vec2, void).init(allocator);
    defer visited.deinit();
    var queue = std.ArrayList(Vec2).init(allocator);
    defer queue.deinit();

    try queue.append(Vec2{ .row = start_row, .col = start_col });

    var num_trailheads: usize = 0;

    while (queue.items.len > 0) {
        const next = queue.pop();
        const current_height = grid.at(next.row, next.col).?;

        try visited.put(next, undefined);

        if (current_height == 9) {
            num_trailheads += 1;
        }

        // down
        if (is_edge(&visited, grid, next.row + 1, next.col, current_height)) {
            try queue.append(Vec2{ .row = next.row + 1, .col = next.col });
        }
        if (is_edge(&visited, grid, next.row - 1, next.col, current_height)) {
            try queue.append(Vec2{ .row = next.row - 1, .col = next.col });
        }
        if (is_edge(&visited, grid, next.row, next.col + 1, current_height)) {
            try queue.append(Vec2{ .row = next.row, .col = next.col + 1 });
        }
        if (is_edge(&visited, grid, next.row, next.col - 1, current_height)) {
            try queue.append(Vec2{ .row = next.row, .col = next.col - 1 });
        }
    }
    return num_trailheads;
}

fn valid_position(grid: *const Grid, row: i32, col: i32, current_height: usize) bool {
    return grid.in_bounds(row, col) and grid.at(row, col) == @as(u32, @intCast(current_height + 1));
}

fn dp_count_paths(next: Vec2, memory: *std.AutoHashMap(Vec2, usize), grid: *const Grid) !usize {
    const current_height = grid.at(next.row, next.col).?;
    if (current_height == 9) {
        return 1;
    }

    if (memory.get(next)) |v| {
        return v;
    }

    var num_paths: usize = 0;

    if (valid_position(grid, next.row + 1, next.col, current_height)) {
        num_paths += try dp_count_paths(Vec2{ .row = next.row + 1, .col = next.col }, memory, grid);
    }
    if (valid_position(grid, next.row - 1, next.col, current_height)) {
        num_paths += try dp_count_paths(Vec2{ .row = next.row - 1, .col = next.col }, memory, grid);
    }
    if (valid_position(grid, next.row, next.col + 1, current_height)) {
        num_paths += try dp_count_paths(Vec2{ .row = next.row, .col = next.col + 1 }, memory, grid);
    }
    if (valid_position(grid, next.row, next.col - 1, current_height)) {
        num_paths += try dp_count_paths(Vec2{ .row = next.row, .col = next.col - 1 }, memory, grid);
    }

    try memory.put(next, num_paths);

    return num_paths;
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

    var grid = try Grid.init(allocator, buff);
    defer grid.deinit();

    var dp_memory = std.AutoHashMap(Vec2, usize).init(allocator);
    defer dp_memory.deinit();

    var part1_answer: usize = 0;
    var part2_answer: usize = 0;
    for (0..grid.height) |row| {
        for (0..grid.width) |col| {
            const row_i32: i32 = @as(i32, @intCast(row));
            const col_i32: i32 = @as(i32, @intCast(col));
            if (grid.at(row_i32, col_i32) == 0) {
                part1_answer += try dfs_find_end_points(allocator, &grid, col_i32, row_i32);
                part2_answer += try dp_count_paths(Vec2{ .row = row_i32, .col = col_i32 }, &dp_memory, &grid);
            }
        }
    }

    print("Part1: {}\n", .{part1_answer});
    print("Part2: {}\n", .{part2_answer});
}

const EXAMPLE =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test "grid" {
    var grid = try Grid.init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    try testing.expectEqual(8, grid.width);
    try testing.expectEqual(8, grid.height);
}

test "dfs" {
    var grid = try Grid.init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    try testing.expectEqual(5, try dfs_find_end_points(testing.allocator, &grid, 2, 0));
    try testing.expectEqual(6, try dfs_find_end_points(testing.allocator, &grid, 4, 0));
    try testing.expectEqual(5, try dfs_find_end_points(testing.allocator, &grid, 4, 2));
    try testing.expectEqual(3, try dfs_find_end_points(testing.allocator, &grid, 6, 4));
    try testing.expectEqual(1, try dfs_find_end_points(testing.allocator, &grid, 2, 5));
    try testing.expectEqual(3, try dfs_find_end_points(testing.allocator, &grid, 5, 5));
    try testing.expectEqual(5, try dfs_find_end_points(testing.allocator, &grid, 0, 6));
    try testing.expectEqual(3, try dfs_find_end_points(testing.allocator, &grid, 6, 6));
    try testing.expectEqual(5, try dfs_find_end_points(testing.allocator, &grid, 1, 7));
}

test "dp_count_paths - single start end" {
    const example =
        \\.....0.
        \\..4321.
        \\..5..2.
        \\..6543.
        \\..7..4.
        \\..8765.
        \\..9....
    ;
    var grid = try Grid.init(testing.allocator, example);
    defer grid.deinit();

    var memory = std.AutoHashMap(Vec2, usize).init(testing.allocator);
    defer memory.deinit();

    try testing.expectEqual(3, dp_count_paths(Vec2{ .row = 0, .col = 5 }, &memory, &grid));
}

test "dp_count_paths - multiple end" {
    const example =
        \\..90..9
        \\...1.98
        \\...2..7
        \\6543456
        \\765.987
        \\876....
        \\987....
    ;
    var grid = try Grid.init(testing.allocator, example);
    defer grid.deinit();

    var memory = std.AutoHashMap(Vec2, usize).init(testing.allocator);
    defer memory.deinit();

    try testing.expectEqual(13, dp_count_paths(Vec2{ .row = 0, .col = 3 }, &memory, &grid));
}

test "dp_count_paths - multiple start and ends" {
    const example =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    var grid = try Grid.init(testing.allocator, example);
    defer grid.deinit();

    var memory = std.AutoHashMap(Vec2, usize).init(testing.allocator);
    defer memory.deinit();

    try testing.expectEqual(20, dp_count_paths(Vec2{ .row = 0, .col = 2 }, &memory, &grid));
    try testing.expectEqual(24, dp_count_paths(Vec2{ .row = 0, .col = 4 }, &memory, &grid));
    try testing.expectEqual(10, dp_count_paths(Vec2{ .row = 2, .col = 4 }, &memory, &grid));
    try testing.expectEqual(4, dp_count_paths(Vec2{ .row = 4, .col = 6 }, &memory, &grid));
    try testing.expectEqual(1, dp_count_paths(Vec2{ .row = 5, .col = 2 }, &memory, &grid));
    try testing.expectEqual(4, dp_count_paths(Vec2{ .row = 5, .col = 5 }, &memory, &grid));
    try testing.expectEqual(5, dp_count_paths(Vec2{ .row = 6, .col = 0 }, &memory, &grid));
    try testing.expectEqual(8, dp_count_paths(Vec2{ .row = 6, .col = 6 }, &memory, &grid));
    try testing.expectEqual(5, dp_count_paths(Vec2{ .row = 7, .col = 1 }, &memory, &grid));
}

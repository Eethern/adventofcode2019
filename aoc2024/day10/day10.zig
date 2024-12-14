const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

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
    return !visited.contains(Vec2{.col=col, .row=row}) and grid.in_bounds(row, col) and grid.at(row, col).? == current_height + 1;
}

fn dfs_find_end_points(allocator: std.mem.Allocator, grid: *const Grid, start_col: i32, start_row: i32) !usize {
    var visited = std.AutoHashMap(Vec2, void).init(allocator);
    defer visited.deinit();
    var queue = std.ArrayList(Vec2).init(allocator);
    defer queue.deinit();

    try queue.append(Vec2{.row=start_row, .col=start_col});

    var num_trailheads: usize = 0;

    while (queue.items.len > 0) {
        const next = queue.pop();
        const current_height = grid.at(next.row, next.col).?;

        try visited.put(next, undefined);

        if (current_height == 9) {
            num_trailheads += 1;
        }

        // down
        if (is_edge(&visited, grid, next.row+1, next.col, current_height)) {
            try queue.append(Vec2{.row=next.row+1, .col=next.col});
        }
        if (is_edge(&visited, grid, next.row-1, next.col, current_height)) {
            try queue.append(Vec2{.row=next.row-1, .col=next.col});
        }
        if (is_edge(&visited, grid, next.row, next.col+1, current_height)) {
            try queue.append(Vec2{.row=next.row, .col=next.col+1});
        }
        if (is_edge(&visited, grid, next.row, next.col-1, current_height)) {
            try queue.append(Vec2{.row=next.row, .col=next.col-1});
        }
    }
    return num_trailheads;
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

fn part1(allocator: std.mem.Allocator, grid: *const Grid) !usize {
    var part1_answer: usize = 0;
    for (0..grid.height) |row| {
        for (0..grid.width) |col| {
            const row_i32: i32 = @as(i32, @intCast(row));
            const col_i32: i32 = @as(i32, @intCast(col));
            if (grid.at(row_i32, col_i32) == 0) {
                part1_answer += try dfs_find_end_points(allocator, grid, col_i32, row_i32);
            }
        }
    }
    return part1_answer;
}


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var grid = try Grid.init(allocator, buff);
    defer grid.deinit();

    const part1_answer = try part1(allocator, &grid);

    print("Part1: {}\n", .{part1_answer});
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

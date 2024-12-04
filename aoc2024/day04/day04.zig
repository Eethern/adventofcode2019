const print = std.debug.print;
const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,
};

const Dir = enum(usize) {
    NW = 0,
    N,
    NE,
    E,
    SE,
    S,
    SW,
    W,

    pub fn to_vec2(self: Dir) Vec2 {
        return switch (self) {
            .NW => Vec2{ .x = -1, .y = 1 },
            .N => Vec2{ .x = 0, .y = 1 },
            .NE => Vec2{ .x = 1, .y = 1 },
            .E => Vec2{ .x = 1, .y = 0 },
            .SE => Vec2{ .x = 1, .y = -1 },
            .S => Vec2{ .x = 0, .y = -1 },
            .SW => Vec2{ .x = -1, .y = -1 },
            .W => Vec2{ .x = -1, .y = 0 },
        };
    }
};

const ALL_DIRS: [8]Dir = [8]Dir{
    .NW,
    .N,
    .NE,
    .E,
    .SE,
    .S,
    .SW,
    .W,
};

const Grid = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !Grid {
        var data = std.ArrayList(u8).init(allocator);
        var lines = std.mem.split(u8, bytes, "\n");
        var row: usize = 0;
        var width: usize = 0;
        while (lines.next()) |line| {
            for (0.., line) |col, c| {
                try data.append(c);
                width = @max(col, width);
            }
            row += 1;
        }

        return Grid{ .width = width + 1, .height = row - 1, .data = data };
    }

    pub fn deinit(self: *Grid) void {
        self.data.deinit();
    }

    pub fn at(self: *Grid, row: i32, col: i32) ?u8 {
        if (row >= 0 and row < self.height and col >= 0 and col < self.width) {
            const width: i32 = @intCast(self.width);
            const idx: usize = @intCast(row * width + col);
            return self.data.items[idx];
        } else {
            return null;
        }
    }

    pub fn check(self: *Grid, row: i32, col: i32, dir: Dir, keyword: []const u8) bool {
        const d = dir.to_vec2();

        var x = row;
        var y = col;
        for (keyword) |token| {
            if (self.at(x, y) != token) {
                return false;
            }
            x += d.x;
            y += d.y;
        }
        return true;
    }

    pub fn check_xmas(self: *Grid, row: i32, col: i32) bool {
        if (self.at(col, row) != 'A') {
            return false;
        }

        if (row < 1 or row > self.height - 1 or col < 1 or col > self.width - 1) {
            return false;
        }

        const nw = self.at(col - 1, row + 1);
        const ne = self.at(col + 1, row + 1);
        const sw = self.at(col - 1, row - 1);
        const se = self.at(col + 1, row - 1);

        // Just hardcode it
        if ((nw == 'M' and se == 'S' and ne == 'M' and sw == 'S') or
            (nw == 'M' and se == 'S' and ne == 'S' and sw == 'M') or
            (nw == 'S' and se == 'M' and ne == 'M' and sw == 'S') or
            (nw == 'S' and se == 'M' and ne == 'S' and sw == 'M'))
        {
            return true;
        }
        return false;
    }

    pub fn count_keyword(self: *Grid, keyword: []const u8) usize {
        var num_keyword: usize = 0;
        for (ALL_DIRS) |dir| {
            for (0..self.width) |x| {
                for (0..self.height) |y| {
                    if (self.check(@intCast(y), @intCast(x), dir, keyword)) {
                        num_keyword += 1;
                    }
                }
            }
        }
        return num_keyword;
    }

    pub fn count_xmasses(self: *Grid) usize {
        var num_keyword: usize = 0;
        for (1..self.width - 1) |x| {
            for (1..self.height - 1) |y| {
                if (self.check_xmas(@intCast(y), @intCast(x))) {
                    num_keyword += 1;
                }
            }
        }
        return num_keyword;
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

    var grid = try Grid.init(allocator, buff);
    defer grid.deinit();

    print("Part1: {?}\n", .{grid.count_keyword("XMAS")});
    print("Part2: {?}\n", .{grid.count_xmasses()});

    allocator.free(buff);
}

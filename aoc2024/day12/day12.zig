const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const Cell = struct {
    plant: u8,
    plot_id: ?u32 = null,
};

const Vec2 = struct { row: i32, col: i32 };

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
                    try data.append(Cell{ .plant = c });
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

        pub fn display(self: *const Self) void {
            for (0..self.height) |row| {
                const row_i32: i32 = @as(i32, @intCast(row));
                for (0..self.width) |col| {
                    const col_i32: i32 = @as(i32, @intCast(col));
                    const c = self.at(row_i32, col_i32).?.plant;
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

const FloodResult = struct {
    perimiter: usize = 0,
    area: usize = 0,
};

fn flood_fill(allocator: std.mem.Allocator, grid: *Grid(Cell), src_row: i32, src_col: i32) !?FloodResult {
    if (!grid.in_bounds(src_row, src_col)) {
        return error.CellOutOfBounds;
    }
    const start_pos = Vec2{ .row = src_row, .col = src_col };
    var start_cell = grid.at_vec2(start_pos).?;
    if (start_cell.plot_id != null) return null;

    var stack = std.ArrayList(Vec2).init(allocator);
    defer stack.deinit();

    // visit start
    try stack.append(start_pos);
    start_cell.plot_id = start_cell.plant;

    var flood_result = FloodResult{};
    while (stack.items.len > 0) {
        const next = stack.pop();
        flood_result.area += 1;

        for (ALL_DIRS) |dir| {
            const dv = dir.to_vec();
            const neighbor = Vec2{ .row = next.row + dv.row, .col = next.col + dv.col };

            if (grid.in_bounds(neighbor.row, neighbor.col)) {
                const neighbor_cell = grid.at_vec2(neighbor).?;
                if (neighbor_cell.plot_id == start_cell.plot_id) continue;

                if (neighbor_cell.plant != start_cell.plant) {
                    flood_result.perimiter += 1;
                } else {
                    neighbor_cell.plot_id = start_cell.plant;
                    try stack.append(neighbor);
                }
            } else {
                flood_result.perimiter += 1;
            }
        }
    }
    return flood_result;
}

fn compute_total_price(allocator: std.mem.Allocator, grid: *Grid(Cell)) !usize {
    var total_price: usize = 0;
    for (0..grid.height) |row| {
        const row_i32: i32 = @as(i32, @intCast(row));
        for (0..grid.width) |col| {
            const col_i32: i32 = @as(i32, @intCast(col));
            const result = try flood_fill(allocator, grid, row_i32, col_i32);
            if (result != null) {
                total_price += result.?.area * result.?.perimiter;
            }
        }
    }
    return total_price;
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

    var grid = try Grid(Cell).init(allocator, buff);
    defer grid.deinit();

    const part1_answer = try compute_total_price(allocator, &grid);
    print("Part1: {}\n", .{part1_answer});
}

const EXAMPLE =
    \\AAAA
    \\BBCD
    \\BBCC
    \\EEEC
;

test "grid" {
    var grid = try Grid(Cell).init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    try testing.expectEqual(4, grid.width);
    try testing.expectEqual(4, grid.height);

    grid.display();
}

test "flood_fill" {
    var grid = try Grid(Cell).init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    const result_a = try flood_fill(testing.allocator, &grid, 0, 0);
    try testing.expectEqual(4, result_a.?.area);
    try testing.expectEqual(10, result_a.?.perimiter);

    const result_b = try flood_fill(testing.allocator, &grid, 1, 0);
    try testing.expectEqual(4, result_b.?.area);
    try testing.expectEqual(8, result_b.?.perimiter);

    const result_c = try flood_fill(testing.allocator, &grid, 1, 2);
    try testing.expectEqual(4, result_c.?.area);
    try testing.expectEqual(10, result_c.?.perimiter);

    const result_d = try flood_fill(testing.allocator, &grid, 1, 3);
    try testing.expectEqual(1, result_d.?.area);
    try testing.expectEqual(4, result_d.?.perimiter);

    const result_e = try flood_fill(testing.allocator, &grid, 3, 0);
    try testing.expectEqual(3, result_e.?.area);
    try testing.expectEqual(8, result_e.?.perimiter);
}

test "flood all" {
    var grid = try Grid(Cell).init(testing.allocator, EXAMPLE);
    defer grid.deinit();

    try testing.expectEqual(140, try compute_total_price(testing.allocator, &grid));
}

test "flood all big example" {
    const example =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;

    var grid = try Grid(Cell).init(testing.allocator, example);
    defer grid.deinit();

    try testing.expectEqual(1930, try compute_total_price(testing.allocator, &grid));
}

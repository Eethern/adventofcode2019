const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const testing = std.testing;

const Antenna = struct {
    freq: u8,
    pos: Vec2,
};

const Antinode = struct { pos: Vec2 };

const Vec2 = @Vector(2, i32);

const FrequencyToAntennas = std.AutoArrayHashMap(u8, std.ArrayList(Antenna));
const AntinodeSet = std.AutoArrayHashMap(Antinode, void);

const Problem = struct {
    allocator: std.mem.Allocator,
    antenna_map: FrequencyToAntennas,
    grid_width: isize,
    grid_height: isize,

    pub fn init_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Problem {
        var row: usize = 0;
        var width: usize = 0;

        var antenna_map = FrequencyToAntennas.init(allocator);
        var lines = std.mem.split(u8, bytes, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) {
                break;
            }

            for (0.., line) |col, c| {
                width = @max(col, width);

                switch (c) {
                    '.' => continue,
                    else => {
                        const antenna = Antenna{ .freq = c, .pos = .{ @as(i32, @intCast(col)), @as(i32, @intCast(row)) } };
                        if (!antenna_map.contains(c)) {
                            try antenna_map.put(c, std.ArrayList(Antenna).init(allocator));
                        }
                        try antenna_map.getPtr(c).?.append(antenna);
                    },
                }
            }
            row += 1;
        }

        return Problem{
            .allocator = allocator,
            .antenna_map = antenna_map,
            .grid_width = @intCast(width + 1),
            .grid_height = @intCast(row),
        };
    }

    pub fn deinit(self: *Problem) void {
        var it = self.antenna_map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }

        self.antenna_map.deinit();
    }

    pub fn vec_outside_bounds(self: *const Problem, vec: Vec2) bool {
        return (vec[0] < 0 or vec[0] > self.grid_width - 1 or vec[1] < 0 or vec[1] > self.grid_height - 1);
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

pub fn populate_antinodes(antenna_a: *const Antenna, antenna_b: *const Antenna, antinode_set: *AntinodeSet) !void {
    if (antenna_a.freq != antenna_b.freq) {
        return error.MismatchingFrequencies;
    }

    const b_to_a = antenna_b.pos - antenna_a.pos;
    const antinode1 = Antinode{ .pos = antenna_a.pos - b_to_a };
    const antinode2 = Antinode{ .pos = antenna_b.pos + b_to_a };

    try antinode_set.put(antinode1, undefined);
    try antinode_set.put(antinode2, undefined);
}

pub fn populate_antinodes_part2(problem: *const Problem, antenna_a: *const Antenna, antenna_b: *const Antenna, antinode_set: *AntinodeSet) !void {
    if (antenna_a.freq != antenna_b.freq) {
        return error.MismatchingFrequencies;
    }

    const b_to_a = antenna_b.pos - antenna_a.pos;
    var d: Vec2 = .{ 0, 0 };
    while (true) {
        const a_pos = antenna_a.pos - d;
        const b_pos = antenna_b.pos + d;
        const a_outside_bounds = problem.vec_outside_bounds(a_pos);
        const b_outside_bounds = problem.vec_outside_bounds(b_pos);
        if (!a_outside_bounds) {
            const antinode1 = Antinode{ .pos = a_pos };
            try antinode_set.put(antinode1, undefined);
        }

        if (!b_outside_bounds) {
            const antinode2 = Antinode{ .pos = b_pos };
            try antinode_set.put(antinode2, undefined);
        }

        if (a_outside_bounds and b_outside_bounds) {
            break;
        }

        d += b_to_a;
    }
}

pub fn create_antinode_set(allocator: std.mem.Allocator, problem: *const Problem, part2: bool) !AntinodeSet {
    var antinode_set = AntinodeSet.init(allocator);

    var it = problem.antenna_map.iterator();
    while (it.next()) |entry| {
        for (0.., entry.value_ptr.items) |i, antenna_a| {
            for (0.., entry.value_ptr.items) |j, antenna_b| {
                if (i == j) continue;
                if (part2) {
                    try populate_antinodes_part2(problem, &antenna_a, &antenna_b, &antinode_set);
                } else {
                    try populate_antinodes(&antenna_a, &antenna_b, &antinode_set);
                }
            }
        }
    }
    return antinode_set;
}

pub fn compute_number_of_antinode_in_bounds(antinode_set: *const AntinodeSet, problem: *const Problem) usize {
    var antinode_it = antinode_set.iterator();
    var num_antinodes: usize = 0;
    while (antinode_it.next()) |an| {
        const pos = an.key_ptr.*.pos;
        if (problem.vec_outside_bounds(pos)) {
            continue;
        }
        num_antinodes += 1;
    }
    return num_antinodes;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();
    const grid_bytes = try read_file(allocator, "input.txt");
    defer allocator.free(grid_bytes);

    var problem = try Problem.init_from_bytes(allocator, grid_bytes);
    defer problem.deinit();

    var antinode_set = try create_antinode_set(allocator, &problem, false);
    defer antinode_set.deinit();

    var antinode_set_part2 = try create_antinode_set(allocator, &problem, true);
    defer antinode_set_part2.deinit();

    const part1_answer: usize = compute_number_of_antinode_in_bounds(&antinode_set, &problem);
    const part2_answer: usize = compute_number_of_antinode_in_bounds(&antinode_set_part2, &problem);
    print("Part1 {}\n", .{part1_answer});
    print("Part2 {}\n", .{part2_answer});
}

const GRID_BYTES =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

test "parse_problem" {
    var problem = try Problem.init_from_bytes(testing.allocator, GRID_BYTES);
    defer problem.deinit();

    try testing.expectEqual(12, problem.grid_width);
    try testing.expectEqual(12, problem.grid_height);
}

test "compute_antinodes_wrong_freq" {
    const a = Antenna{ .freq = 'a', .pos = .{ 2, 2 } };
    const b = Antenna{ .freq = 'b', .pos = .{ 6, 6 } };
    var antinode_set = AntinodeSet.init(testing.allocator);

    try testing.expectError(error.MismatchingFrequencies, populate_antinodes(&a, &b, &antinode_set));
}

test "compute_antinodes_correct_freq" {
    const a = Antenna{ .freq = 'a', .pos = .{ 4, 3 } };
    const b = Antenna{ .freq = 'a', .pos = .{ 5, 5 } };
    var antinode_set = AntinodeSet.init(testing.allocator);
    defer antinode_set.deinit();
    try populate_antinodes(&a, &b, &antinode_set);

    try testing.expectEqual(antinode_set.count(), 2);

    const expected_antinode1 = Antinode{ .pos = .{ 3, 1 } };
    const expected_antinode2 = Antinode{ .pos = .{ 6, 7 } };
    const unexpected_antinode = Antinode{ .pos = .{ 2, 2 } };

    try testing.expect(antinode_set.contains(expected_antinode1));
    try testing.expect(antinode_set.contains(expected_antinode2));
    try testing.expect(!antinode_set.contains(unexpected_antinode));
}

test "multiple_antinodes" {
    var problem = try Problem.init_from_bytes(testing.allocator, GRID_BYTES);
    defer problem.deinit();

    var antinode_set = try create_antinode_set(testing.allocator, &problem, false);
    defer antinode_set.deinit();

    const num_antinodes: usize = compute_number_of_antinode_in_bounds(&antinode_set, &problem);
    try testing.expectEqual(14, num_antinodes);
}

test "part2_antinodes" {
    var problem = try Problem.init_from_bytes(testing.allocator, GRID_BYTES);
    defer problem.deinit();

    var antinode_set = try create_antinode_set(testing.allocator, &problem, true);
    defer antinode_set.deinit();

    try testing.expectEqual(34, antinode_set.count());
}

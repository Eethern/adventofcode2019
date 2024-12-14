const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

fn num_digits(num: u64) usize {
    var n = num;
    var digits: u64 = 0;
    while (n > 0) : (n /= 10) {
        digits += 1;
    }
    return digits;
}

fn split_number(num: u64) struct { a: u64, b: u64 } {
    // Determine the number of digits
    const digits = num_digits(num);
    if (digits == 0) {
        return .{ .a = 0, .b = 0 };
    }

    // Find the split point
    const half = digits / 2;

    // Compute the divisor for the split
    var divisor: u64 = 1;
    for (0..half) |i| {
        _ = i; // Discard loop variable
        divisor *= 10;
    }

    // Perform the split
    const a = @as(u64, num / divisor);
    const b = @as(u64, num % divisor);

    return .{ .a = a, .b = b };
}

fn add_count(counts: *std.AutoArrayHashMap(u64, u64), key: u64, value: u64) !void {
    if (counts.get(key)) |v| {
        try counts.put(key, v + value);
    } else {
        try counts.put(key, value);
    }
}

const Counts = std.AutoArrayHashMap(u64, u64);

fn tick_generation(counts_in: *const Counts, counts_out: *Counts) !void {
    var it = counts_in.iterator();
    while (it.next()) |*entry| {
        const engraving = entry.key_ptr.*;
        if (engraving == 0) {
            try add_count(counts_out, 1, entry.value_ptr.*);
        } else if (num_digits(engraving) % 2 == 0) {
            const result = split_number(engraving);
            try add_count(counts_out, result.a, entry.value_ptr.*);
            try add_count(counts_out, result.b, entry.value_ptr.*);
        } else {
            try add_count(counts_out, engraving * 2024, entry.value_ptr.*);
        }
    }
}

fn populate_counts(bytes: []const u8, counts: *Counts) !void {
    var it = std.mem.tokenizeAny(u8, bytes, " \n");
    while (it.next()) |token| {
        if (token.len == 0) break;
        const engraving: u64 = try std.fmt.parseInt(u64, token, 10);
        try add_count(counts, engraving, 1);
    }
}

fn count_stones(counts: *const Counts) usize {
    var num_stones: usize = 0;
    var it = counts.iterator();
    while (it.next()) |*entry| {
        num_stones += entry.value_ptr.*;
    }
    return num_stones;
}

fn tick_generations(counts_in: *Counts, counts_out: *Counts, num_generations: usize) !void {
    var counts_in_ptr = counts_in;
    var counts_out_ptr = counts_out;
    for (0..num_generations) |_| {
        try tick_generation(counts_in_ptr, counts_out_ptr);

        const t_ptr = counts_in_ptr;
        counts_in_ptr = counts_out_ptr;
        counts_out_ptr = t_ptr;
        counts_out_ptr.clearAndFree();
    }
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

    var counts = Counts.init(allocator);
    defer counts.deinit();
    var counts_two = Counts.init(allocator);
    defer counts_two.deinit();

    try populate_counts(buff, &counts);

    try tick_generations(&counts, &counts_two, 25);
    print("Part1: {}\n", .{count_stones(&counts_two)});
    try tick_generations(&counts_two, &counts, 75 - 25);
    print("Part2: {}\n", .{count_stones(&counts_two)});
}

test "split number" {
    const result = split_number(1020);
    try testing.expectEqual(10, result.a);
    try testing.expectEqual(20, result.b);

    const result2 = split_number(1000);
    try testing.expectEqual(10, result2.a);
    try testing.expectEqual(0, result2.b);
}

test "tick generation" {
    const input = "125 17";
    var counts = Counts.init(testing.allocator);
    defer counts.deinit();

    try populate_counts(input, &counts);

    var counts_switch = Counts.init(testing.allocator);
    defer counts_switch.deinit();

    try tick_generations(&counts, &counts_switch, 6);

    try testing.expectEqual(22, count_stones(&counts));
}

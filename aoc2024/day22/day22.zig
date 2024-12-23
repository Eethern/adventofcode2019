const std = @import("std");
const testing = std.testing;

fn hash(num: u64) u64 {
    var out = num;
    out = (out ^ (out << 6)) % (1 << 24);
    out = (out ^ (out >> 5)) % (1 << 24);
    out = (out ^ (out << 11)) % (1 << 24);
    return out;
}

fn hash_n(num: u64, n: usize) u64 {
    var out = num;
    for (0..n) |_| {
        out = hash(out);
    }
    return out;
}

fn diff(a: u64, b: u64) i64 {
    return @as(i64, @intCast(b)) - @as(i64, @intCast(a));
}

const Window = @Vector(4, i64);

fn compute_windowed_scores(buyer: u64, n: usize, scores_out: *std.AutoArrayHashMap(Window, u64)) !void {
    var a = hash(buyer);
    var b = hash(a);
    var c = hash(b);
    var d = hash(c);
    var e = hash(d);
    for (4..n) |_| {
        const d1 = diff(a % 10, b % 10);
        const d2 = diff(b % 10, c % 10);
        const d3 = diff(c % 10, d % 10);
        const d4 = diff(d % 10, e % 10);

        const window = Window{ d1, d2, d3, d4 };
        if (!scores_out.contains(window)) {
            try scores_out.put(window, e % 10);
        }

        a = b;
        b = c;
        c = d;
        d = e;
        e = hash(e);
    }
}

fn compute_global_scores(allocator: std.mem.Allocator, bytes: []const u8, n: usize) !u64 {
    var global_scores = std.AutoArrayHashMap(Window, u64).init(allocator);
    defer global_scores.deinit();
    var local_scores = std.AutoArrayHashMap(Window, u64).init(allocator);
    defer local_scores.deinit();

    var number_it = std.mem.tokenizeScalar(u8, bytes, '\n');
    while (number_it.next()) |line| {
        const buyer = try std.fmt.parseInt(u64, line, 10);
        try compute_windowed_scores(buyer, n, &local_scores);
        var local_iter = local_scores.iterator();
        while (local_iter.next()) |*entry| {
            if (global_scores.getPtr(entry.key_ptr.*)) |value_ptr| {
                try global_scores.put(entry.key_ptr.*, value_ptr.* + entry.value_ptr.*);
            } else {
                try global_scores.put(entry.key_ptr.*, entry.value_ptr.*);
            }
        }

        local_scores.clearAndFree();
    }

    var global_iter = global_scores.iterator();
    var num_bananas: u64 = 0;
    while (global_iter.next()) |*entry| {
        num_bananas = @max(num_bananas, entry.value_ptr.*);
    }

    return num_bananas;
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

    var number_it = std.mem.tokenizeScalar(u8, bytes, '\n');
    var part1_answer: u64 = 0;
    while (number_it.next()) |n| {
        const in = try std.fmt.parseInt(u64, n, 10);
        part1_answer += hash_n(in, 2000);
    }

    const part2_answer: u64 = try compute_global_scores(allocator, bytes, 2000);
    std.debug.print("Part2: {}\n", .{part2_answer});
}

const EXAMPLE =
    \\1
    \\2
    \\3
    \\2024
;

test "hash" {
    try testing.expectEqual(15887950, hash(123));
    try testing.expectEqual(16495136, hash(15887950));
    try testing.expectEqual(527345, hash(16495136));
    try testing.expectEqual(704524, hash(527345));
    try testing.expectEqual(1553684, hash(704524));
    try testing.expectEqual(12683156, hash(1553684));
    try testing.expectEqual(11100544, hash(12683156));
    try testing.expectEqual(12249484, hash(11100544));
    try testing.expectEqual(7753432, hash(12249484));
    try testing.expectEqual(5908254, hash(7753432));
}

test "iterate hash" {
    try testing.expectEqual(8685429, hash_n(1, 2000));
    try testing.expectEqual(4700978, hash_n(10, 2000));
    try testing.expectEqual(15273692, hash_n(100, 2000));
    try testing.expectEqual(8667524, hash_n(2024, 2000));
}

test "part2" {
    const answer: u64 = try compute_global_scores(testing.allocator, EXAMPLE, 2000);
    try testing.expectEqual(23, answer);
}

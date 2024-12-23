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

    std.debug.print("Part1: {}\n", .{part1_answer});
}

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

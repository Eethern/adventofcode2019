const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("01.txt");

fn read_input(left_list: *std.ArrayList(u32), right_list: *std.ArrayList(u32)) !void {
    var it = std.mem.tokenizeAny(u8, input, " \n");
    var token_idx: usize = 0;
    while (it.next()) |token| {
        const number: u32 = try std.fmt.parseInt(u32, token, 10);
        if (token_idx % 2 == 0) {
            try left_list.append(number);
        } else {
            try right_list.append(number);
        }
        token_idx += 1;
    }
}

fn part1(left_list: *std.ArrayList(u32), right_list: *std.ArrayList(u32)) u32 {
    var sum: u32 = 0;
    for (left_list.items, right_list.items) |left, right| {
        if (right > left) {
            sum += right - left;
        } else {
            sum += left - right;
        }
    }

    return sum;
}

fn part2(allocator: std.mem.Allocator, left_list: *std.ArrayList(u32), right_list: *std.ArrayList(u32)) !u32 {
    assert(left_list.items.len == right_list.items.len);

    var max_number: u32 = 0;
    for (left_list.items) |number| max_number = @max(max_number, number);
    for (right_list.items) |number| max_number = @max(max_number, number);

    const counts: []u32 = try allocator.alloc(u32, max_number + 1);
    @memset(counts, 0);
    defer allocator.free(counts);
    for (right_list.items) |number| {
        counts[number] += 1;
    }

    var sum: u32 = 0;
    for (left_list.items) |number| {
        sum += number * counts[number];
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var left_list = std.ArrayList(u32).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(u32).init(allocator);
    defer right_list.deinit();
    try read_input(&left_list, &right_list);

    std.mem.sort(u32, left_list.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right_list.items, {}, comptime std.sort.asc(u32));

    assert(left_list.items.len == right_list.items.len);

    print("Part 1: {}\n", .{part1(&left_list, &right_list)});
    print("Part 2: {}\n", .{try part2(allocator, &left_list, &right_list)});
}

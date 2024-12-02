const print = std.debug.print;
const std = @import("std");

const input = @embedFile("input.txt");

fn is_safe(report: []const u8, skip_idx: usize) !bool {
    var line_it = std.mem.tokenizeAny(u8, report, " ");
    var all_positive = true;
    var all_negative = true;
    var prev: i32 = -1;
    var idx: usize = 0;
    while (line_it.next()) |token| {
        if (idx == skip_idx) {
            idx += 1;
            continue;
        }

        const number: i32 = try std.fmt.parseInt(i32, token, 10);
        if (prev == -1) {
            prev = number;
            idx += 1;
            continue;
        }

        const diff = number - prev;
        const mag = @abs(diff);

        if ((mag < 1) or (mag > 3)) {
            return false;
        }

        if (diff < 0) {
            all_positive = false;
        } else {
            all_negative = false;
        }

        idx += 1;
        prev = number;
    }

    return all_positive or all_negative;
}

fn solve_part1(sample: []const u8) !usize {
    var it = std.mem.split(u8, sample, "\n");
    var num_safe: usize = 0;
    while (it.next()) |line| {
        if (try is_safe(line, line.len) and line.len > 0) {
            num_safe += 1;
        }
    }
    return num_safe;
}

fn solve_part2(sample: []const u8) !usize {
    var it = std.mem.split(u8, sample, "\n");
    var num_safe: usize = 0;

    while (it.next()) |line| {
        for (0..it.buffer.len) |skip_idx| {
            if (try is_safe(line, skip_idx) and line.len > 0) {
                num_safe += 1;
                break;
            }
        }
    }

    return num_safe;
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Part 1: {}\n", .{try solve_part1(input)});
    try stdout.print("Part 2: {}\n", .{try solve_part2(input)});
    try bw.flush();
}

test "example" {
    const example = @embedFile("example.txt");
    try std.testing.expect(try solve_part1(example) == 2);
    try std.testing.expect(try solve_part2(example) == 4);
}

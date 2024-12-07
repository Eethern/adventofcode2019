const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const Problem = struct {
    target: u64,
    numbers: std.ArrayList(u64),
};

fn concat(num1: u64, num2: u64) u64 {
    var temp = num2;
    var num2_digits: u64 = 0;
    while (temp > 0) : (temp /= 10) {
        num2_digits += 1;
    }

    const multiplier = std.math.pow(u64, 10, num2_digits);
    return num1 * multiplier + num2;
}

fn valid_equation_rec(target: u64, numbers: []const u64, n: u64, part2: bool) bool {
    if (numbers.len == 0 or n > target) {
        return n == target;
    }
    const next_slice = numbers[1..];
    const next = numbers[0];
    return (part2 and valid_equation_rec(target, next_slice, concat(n, next), part2))
        or valid_equation_rec(target, next_slice, n * next, part2)
        or valid_equation_rec(target, next_slice, n + next, part2);
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

fn parse_problem(allocator: std.mem.Allocator, line: []const u8) !Problem {
    var numbers = std.ArrayList(u64).init(allocator);
    var split = std.mem.splitSequence(u8, line, ": ");
    const target = try std.fmt.parseInt(u64, split.next().?, 10);
    var tokens = std.mem.tokenizeScalar(u8, split.next().?, ' ');
    while (tokens.next()) |token| {
        try numbers.append(try std.fmt.parseInt(u64, token, 10));
    }
    return Problem{
        .target = target,
        .numbers = numbers,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = read_file(allocator, "input.txt") catch |err| {
        print("Could not find input!\n", .{});
        return err;
    };
    defer allocator.free(buff);

    var lines = std.mem.splitScalar(u8, buff, '\n');

    var part1_answer: u64 = 0;
    var part2_answer: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        const problem = parse_problem(allocator, line) catch |err| {
            print("Malformed input {s}\n", .{line});
            return err;
        };
        defer problem.numbers.deinit();
        if (valid_equation_rec(problem.target, problem.numbers.items, 0, false)) {
            part1_answer += problem.target;
        }
        if (valid_equation_rec(problem.target, problem.numbers.items, 0, true)) {
            part2_answer += problem.target;
        }
    }

    print("Part 1: {}\n", .{part1_answer});
    print("Part 2: {}\n", .{part2_answer});
}

test "valid equation" {
    const TestValidEquation = struct {
        const Self = @This();
        outcome: bool,
        target: u64,
        numbers: []const u64,
        part2: bool,

        fn run(self: *const Self) !void {
            try testing.expectEqual(self.outcome, valid_equation_rec(self.target, self.numbers, 0, self.part2));
        }

        fn init(outcome: bool, target: u64, numbers: []const u64, part2: bool) Self {
            return Self{ .outcome = outcome, .target = target, .numbers = numbers, .part2 = part2 };
        }
    };


    try TestValidEquation.init(true, 190, &[_]u64{ 10, 19 }, false).run();
    try TestValidEquation.init(true, 3267, &[_]u64{ 81, 40, 27 }, false).run();
    try TestValidEquation.init(false, 83, &[_]u64{ 17, 5 }, false).run();
    try TestValidEquation.init(false, 156, &[_]u64{ 15, 6 }, false).run();
    try TestValidEquation.init(false, 7290, &[_]u64{ 6, 8, 6, 15 }, false).run();
    try TestValidEquation.init(false, 161011, &[_]u64{ 16, 10, 13 }, false).run();
    try TestValidEquation.init(false, 192, &[_]u64{ 17, 8, 14 }, false).run();
    try TestValidEquation.init(false, 21037, &[_]u64{ 9, 7, 18, 13 }, false).run();
    try TestValidEquation.init(true, 292, &[_]u64{ 11, 6, 16, 20 }, false).run();

    try TestValidEquation.init(false, 573436, &[_]u64{ 65, 11, 802, 3, 6 }, false).run();
    try TestValidEquation.init(false, 89418618, &[_]u64{ 69, 797, 2, 813, 2 }, false).run();

    try TestValidEquation.init(true, 156, &[_]u64{ 15, 6 }, true).run();
    try TestValidEquation.init(true, 7290, &[_]u64{ 6, 8, 6, 15 }, true).run();
    try TestValidEquation.init(true, 192, &[_]u64{ 17, 8, 14 }, true).run();
    try TestValidEquation.init(false, 161011, &[_]u64{ 16, 10, 13 }, true).run();
}

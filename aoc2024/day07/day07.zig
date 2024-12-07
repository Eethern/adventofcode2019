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
    return (part2 and valid_equation_rec(target, next_slice, concat(n, next), part2)) or valid_equation_rec(target, next_slice, n * next, part2) or valid_equation_rec(target, next_slice, n + next, part2);
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
        part_b: bool = false,

        pub fn run(self: *const Self, line: []const u8) !bool {
            const problem = try parse_problem(testing.allocator, line);
            defer problem.numbers.deinit();
            return valid_equation_rec(problem.target, problem.numbers.items, 0, self.part_b);
        }
    };

    const runner_a = TestValidEquation{};
    const runner_b = TestValidEquation{ .part_b = true };

    // part1
    try testing.expect(try runner_a.run("190: 10 19"));
    try testing.expect(try runner_a.run("3267: 81 40 27"));
    try testing.expect(!try runner_a.run("83: 17 5"));
    try testing.expect(!try runner_a.run("156: 15 6"));
    try testing.expect(!try runner_a.run("7290: 6 8 6 15"));
    try testing.expect(!try runner_a.run("161011: 16 10 13"));
    try testing.expect(!try runner_a.run("192: 17 8 14"));
    try testing.expect(!try runner_a.run("21037: 9 7 18 13"));
    try testing.expect(try runner_a.run("292: 11 6 16 20"));

    // longer inputs
    try testing.expect(!try runner_a.run("573436: 65 11 802 3 6"));
    try testing.expect(!try runner_a.run("89418618: 69 797 2 813 2"));
    try testing.expect(!try runner_a.run("18492032561: 8 2 75 138 1 31 9 7 1 8 2"));

    // part2
    try testing.expect(try runner_b.run("156: 15 6"));
    try testing.expect(try runner_b.run("7290: 6 8 6 15"));
    try testing.expect(try runner_b.run("192: 17 8 14"));
    try testing.expect(!try runner_b.run("161011: 16 10 13"));
}

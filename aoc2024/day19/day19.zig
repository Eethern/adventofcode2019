const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const State = struct {
    cursor: usize = 0,
    num_paths: usize = 0,
};

const Problem = struct {
    towels: std.ArrayList([]const u8),
    designs: std.ArrayList([]const u8),

    fn from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Problem {
        var chunk_iter = std.mem.splitSequence(u8, bytes, "\n\n");
        var towel_iter = std.mem.splitSequence(u8, chunk_iter.next().?, ", ");

        var towels = std.ArrayList([]const u8).init(allocator);
        while (towel_iter.next()) |towel| {
            try towels.append(towel);
        }

        var designs = std.ArrayList([]const u8).init(allocator);
        var design_iter = std.mem.splitScalar(u8, chunk_iter.next().?, '\n');
        while (design_iter.next()) |design| {
            if (design.len == 0) break;
            try designs.append(design);
        }

        return Problem{
            .towels = towels,
            .designs = designs,
        };
    }

    fn deinit(self: *Problem) void {
        self.towels.deinit();
        self.designs.deinit();
    }
};

const Memory = std.AutoHashMap(State, usize);

fn valid_extension(design: []const u8, state: *const State, towel: []const u8) bool {
    if (towel.len == 0) return false;
    if (design.len - state.cursor < towel.len) return false;
    return std.mem.eql(u8, design[state.cursor .. state.cursor + towel.len], towel);
}

fn count_paths_rec(design: []const u8, state: State, towels: *const std.ArrayList([]const u8), memory: *Memory) !usize {
    if (memory.getEntry(state)) |*entry| {
        return entry.value_ptr.*;
    }

    if (state.cursor == design.len) {
        return 1;
    }

    var num_paths = state.num_paths;
    for (towels.items) |towel| {
        if (valid_extension(design, &state, towel)) {
            const next_state = State{
                .cursor = state.cursor + towel.len,
                .num_paths = state.num_paths,
            };
            num_paths += try count_paths_rec(design, next_state, towels, memory);
        }
    }

    try memory.put(state, num_paths);

    return num_paths;
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

fn count_possible_designs(problem: *const Problem, memory: *Memory) !usize {
    var num_possible: usize = 0;
    for (problem.designs.items) |design| {
        memory.clearAndFree();
        const state = State{
            .cursor = 0,
        };
        num_possible += if (try count_paths_rec(design, state, &problem.towels, memory) > 0) 1 else 0;
    }
    return num_possible;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bytes = try read_file(allocator, "input.txt");
    defer allocator.free(bytes);

    var problem = try Problem.from_bytes(allocator, bytes);
    defer problem.deinit();
    var memory = Memory.init(allocator);
    defer memory.deinit();

    const part1_answer = try count_possible_designs(&problem, &memory);

    print("Part1: {}\n", .{part1_answer});
}

const EXAMPLE =
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
;

test "parse" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();

    try testing.expectEqual(8, problem.towels.items.len);
    try testing.expectEqual(8, problem.designs.items.len);

    try testing.expectEqualStrings("r", problem.towels.items[0]);
    try testing.expectEqualStrings("br", problem.towels.items[problem.towels.items.len - 1]);

    try testing.expectEqualStrings("brwrr", problem.designs.items[0]);
    try testing.expectEqualStrings("bbrgwb", problem.designs.items[problem.designs.items.len - 1]);
}

test "valid extension" {
    const design = "gbbr";
    const state = State{
        .cursor = 1,
    };

    try testing.expect(!valid_extension(design, &state, "g"));
    try testing.expect(valid_extension(design, &state, "b"));
    try testing.expect(valid_extension(design, &state, "bb"));
    try testing.expect(valid_extension(design, &state, "bbr"));
    try testing.expect(!valid_extension(design, &state, "hello"));
    try testing.expect(!valid_extension(design, &state, ""));
}

test "count paths" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();
    var memory = Memory.init(testing.allocator);
    defer memory.deinit();
    const state = State{
        .cursor = 0,
    };
    const num_paths = try count_paths_rec(problem.designs.items[0], state, &problem.towels, &memory);
    try testing.expectEqual(2, num_paths);
}

test "solve_problems" {
    var problem = try Problem.from_bytes(testing.allocator, EXAMPLE);
    defer problem.deinit();
    var memory = Memory.init(testing.allocator);
    defer memory.deinit();

    try testing.expectEqual(6, count_possible_designs(&problem, &memory));
}

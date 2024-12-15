const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

fn parse_button_string(bytes: []const u8) ![2]i64 {
    var tokens_iter = std.mem.splitAny(u8, bytes, "+,");

    _ = tokens_iter.next(); // Button A: X+
    const c1 = try std.fmt.parseInt(i64, tokens_iter.next().?, 10);
    _ = tokens_iter.next(); // , Y
    const c2 = try std.fmt.parseInt(i64, tokens_iter.next().?, 10);

    return .{c1, c2};
}

fn parse_prize_string(bytes: []const u8) ![2]i64 {
    var tokens_iter = std.mem.splitAny(u8, bytes, "=,");

    _ = tokens_iter.next(); // Prize: X=
    const c1 = try std.fmt.parseInt(i64, tokens_iter.next().?, 10);
    _ = tokens_iter.next(); // , Y=
    const c2 = try std.fmt.parseInt(i64, tokens_iter.next().?, 10);

    return .{c1, c2};
}

const Problem = struct {
    ax: i64,
    ay: i64,
    bx: i64,
    by: i64,
    px: i64,
    py: i64,
    fn from_bytes(bytes: []const u8) !Problem {
        var lines_iter = std.mem.splitScalar(u8, bytes, '\n');
        const button_a_line = lines_iter.next().?;
        const button_b_line = lines_iter.next().?;
        const prize_line = lines_iter.next().?;
        const ax, const ay = try parse_button_string(button_a_line);
        const bx, const by = try parse_button_string(button_b_line);
        const px, const py = try parse_prize_string(prize_line);

        return Problem{.ax=ax, .ay=ay, .bx=bx, .by=by, .px=px, .py=py};
    }
};


/// Analytical solution of the linear system
/// Solution to system
/// - an * ax + bn * bx = px
/// - an * ay + bn * by = py
///
/// To solve for bn:
/// - Multiply the first equation by `ay` and the second by `ax` to eliminate `an`:
///   (an * ax + bn * bx) * ay = px * ay
///   (an * ay + bn * by) * ax = py * ax
/// - Subtract the equations:
///   bn * (bx * ay - by * ax) = px * ay - py * ax
/// - Therefore:
///   bn = (px * ay - py * ax) / (bx * ay - by * ax)
///
/// To solve for an:
/// - Substitute bn back into the first equation:
///   an * ax + bn * bx = px
///   an * ax = px - bn * bx
///   an = (px - bn * bx) / ax
fn compute_cost(p: *const Problem) ?i64 {
    const bn_denom = p.by * p.ax - p.bx * p.ay;
    if (bn_denom != 0 and p.ax != 0) {
        const bn_numer = p.ax * p.py - p.px * p.ay;
        if (@mod(bn_numer, bn_denom) == 0) {
            const bn = @divExact(bn_numer, bn_denom);
            const an_denom = p.px - bn*p.bx;
            if (@mod(an_denom, p.ax) == 0) {
                const an = @divExact(an_denom, p.ax);
                return an * 3 + bn;
            }
        }
    }
    return null;
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

    var problems_iter = std.mem.splitSequence(u8, buff, "\n\n");
    var part1_answer: i64 = 0;
    var part2_answer: i64 = 0;
    while(problems_iter.next()) |problem_raw| {
        const problem_a = try Problem.from_bytes(problem_raw);
        var problem_b = problem_a;
        problem_b.px += 10_000_000_000_000;
        problem_b.py += 10_000_000_000_000;
        if (compute_cost(&problem_a)) |cost| {
            part1_answer += cost;
        }

        if (compute_cost(&problem_b)) |cost| {
            part2_answer += cost;
        }
    }
    print("Part1: {}\n", .{part1_answer});
    print("Part2: {}\n", .{part2_answer});
}

const EXAMPLE =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;
test "parse" {
    var problems_iter = std.mem.splitSequence(u8, EXAMPLE, "\n\n");

    const expected_costs: [4]?i64 = .{280, null, 200, null};

    var i: usize = 0;
    while(problems_iter.next()) |problem_raw| : (i += 1) {
        const problem = try Problem.from_bytes(problem_raw);
        try testing.expectEqual(expected_costs[i], compute_cost(&problem));
    }
}

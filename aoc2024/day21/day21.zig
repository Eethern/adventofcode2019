const std = @import("std");
const testing = std.testing;

const Vec2 = struct {
    row: i32,
    col: i32,

    fn init(row: i32, col: i32) Vec2 {
        return Vec2{ .row = row, .col = col };
    }

    fn eq(self: *const Vec2, other: *const Vec2) bool {
        return self.row == other.row and self.col == other.col;
    }
};

const KeypadKind = enum {
    NUMPAD,
    DPAD,
};

const Keypad = struct {
    kind: KeypadKind,
    width: usize,
    height: usize,
    buttons: [4][3]?u8,

    fn init_dpad() Keypad {
        return Keypad{ .width = 3, .height = 2, .kind = KeypadKind.DPAD, .buttons = [4][3]?u8{
            .{ null, '^', 'A' },
            .{ '<', 'v', '>' },
            .{ null, null, null },
            .{ null, null, null },
        } };
    }
    fn init_numpad() Keypad {
        return Keypad{ .width = 3, .height = 4, .kind = KeypadKind.NUMPAD, .buttons = [4][3]?u8{
            .{ '7', '8', '9' },
            .{ '4', '5', '6' },
            .{ '1', '2', '3' },
            .{ null, '0', 'A' },
        } };
    }

    fn at(self: *const Keypad, pos: Vec2) ?u8 {
        if (!self.in_bounds(pos)) return null;
        const row = @as(usize, @intCast(pos.row));
        const col = @as(usize, @intCast(pos.col));
        return self.buttons[row][col];
    }

    fn key_to_pos(self: *const Keypad, key: u8) Vec2 {
        if (self.kind == .NUMPAD) {
            return switch (key) {
                '0' => Vec2.init(3, 1),
                'A' => Vec2.init(3, 2),
                '1' => Vec2.init(2, 0),
                '2' => Vec2.init(2, 1),
                '3' => Vec2.init(2, 2),
                '4' => Vec2.init(1, 0),
                '5' => Vec2.init(1, 1),
                '6' => Vec2.init(1, 2),
                '7' => Vec2.init(0, 0),
                '8' => Vec2.init(0, 1),
                '9' => Vec2.init(0, 2),
                else => unreachable,
            };
        } else {
            return switch (key) {
                '^' => Vec2.init(0, 1),
                'A' => Vec2.init(0, 2),
                '<' => Vec2.init(1, 0),
                'v' => Vec2.init(1, 1),
                '>' => Vec2.init(1, 2),
                else => unreachable,
            };
        }
        return Vec2.init(-1, -1); // unreachable
    }

    fn in_bounds(self: *const Keypad, pos: Vec2) bool {
        return pos.row >= 0 and pos.row < self.height and pos.col >= 0 and pos.col < self.width;
    }
};

// TODO: Consider replacing this nested dynamic array output with a
// fixed size array that keeps track of the length of each string.  //
// One could even null-terminate the strings instead to make it more
// efficient than this.
fn generate_legal_moves(allocator: std.mem.Allocator, src: Vec2, dest: Vec2, keypad: *const Keypad) !std.ArrayList(std.ArrayList(u8)) {
    const dv = Vec2.init(dest.row - src.row, dest.col - src.col);
    const chary: u8 = if (dv.row > 0) 'v' else '^';
    const charx: u8 = if (dv.col > 0) '>' else '<';

    // Iterate all 2^moves combinations
    const num_moves = @as(u6, @as(u6, @intCast(@abs(dv.row))) + @as(u6, @intCast(@abs(dv.col))));
    const num_permutations = (@as(usize, 1) << num_moves);
    var permutations = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, num_permutations);

    var str = try std.ArrayList(u8).initCapacity(allocator, num_moves);
    defer str.deinit();
    for (0..num_permutations) |p| {
        str.clearAndFree();
        var curr = src;

        var valid_str = true;
        for (0..num_moves) |i| {
            const c = if (p & (@as(usize, 1) << @as(u6, @truncate(i))) > 0) chary else charx;
            try str.append(c);

            switch (c) {
                '^' => curr.row -= 1,
                'v' => curr.row += 1,
                '<' => curr.col -= 1,
                '>' => curr.col += 1,
                else => unreachable,
            }

            if (keypad.at(curr) == null) {
                valid_str = false;
                break;
            }
        }

        if (valid_str and curr.row == dest.row and curr.col == dest.col) {
            try permutations.append(try str.clone());
        }
    }

    return permutations;
}

const State = struct {
    pad_idx: usize,
    src_key: u8,
    dest_key: u8,
};

const Memory = std.AutoHashMap(State, usize);

const NUMPAD = Keypad.init_numpad();
const DPAD = Keypad.init_dpad();

fn compute_cost(allocator: std.mem.Allocator, pad_idx: usize, src_key: u8, dest_key: u8, keypad: *const Keypad, memory: *Memory) !usize {
    const state = State{
        .pad_idx = pad_idx,
        .src_key = src_key,
        .dest_key = dest_key,
    };
    if (memory.get(state)) |r| return r;

    const curr_pos = keypad.key_to_pos(src_key);
    const dest_pos = keypad.key_to_pos(dest_key);

    // base cases
    if (pad_idx == 0) {
        return @abs(curr_pos.row - dest_pos.row) + @abs(curr_pos.col - dest_pos.col) + 1;
    }
    if (src_key == dest_key) return 1;

    const moves = try generate_legal_moves(allocator, curr_pos, dest_pos, keypad);
    defer moves.deinit();
    const costs = try allocator.alloc(usize, moves.items.len);
    defer allocator.free(costs);
    for (0.., moves.items) |p, move| {
        // Do the A to first letter
        costs[p] = try compute_cost(allocator, pad_idx - 1, 'A', move.items[0], &DPAD, memory);
        for (1..move.items.len) |i| {
            // Do the intermediate moves
            costs[p] += try compute_cost(allocator, pad_idx - 1, move.items[i - 1], move.items[i], &DPAD, memory);
        }
        // Finish to A
        costs[p] += try compute_cost(allocator, pad_idx - 1, move.items[move.items.len - 1], 'A', &DPAD, memory);
    }

    for (moves.items) |*move| {
        move.deinit();
    }

    var result: usize = std.math.maxInt(usize);
    for (costs) |c| {
        result = @min(result, c);
    }

    try memory.put(state, result);
    return result;
}

fn solve(allocator: std.mem.Allocator, codes: []const u8, num_robots: usize) !usize {
    var memory = std.AutoHashMap(State, usize).init(allocator);
    defer memory.deinit();
    var total_cost: usize = 0;

    var line_iter = std.mem.splitScalar(u8, codes, '\n');
    while (line_iter.next()) |code| {
        if (code.len == 0) break;

        var cost = try compute_cost(allocator, num_robots, 'A', code[0], &NUMPAD, &memory);
        for (1..code.len) |i| {
            cost += try compute_cost(allocator, num_robots, code[i - 1], code[i], &NUMPAD, &memory);
        }

        cost *= try std.fmt.parseInt(usize, code[0 .. code.len - 1], 10);
        total_cost += cost;
    }

    return total_cost;
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

    std.debug.print("Part1: {}\n", .{try solve(allocator, bytes, 2)});
    std.debug.print("Part2: {}\n", .{try solve(allocator, bytes, 25)});
}

test "generate_legal_moves" {
    const keypad = Keypad.init_dpad();
    const legal_moves = try generate_legal_moves(testing.allocator, Vec2.init(1, 0), Vec2.init(0, 2), &keypad);

    for (legal_moves.items) |move| {
        move.deinit();
    }
    defer legal_moves.deinit();
}

test "solve example" {
    try testing.expectEqual(29 * 12, try solve(testing.allocator, "029A", 0));
    try testing.expectEqual(29 * 28, try solve(testing.allocator, "029A", 1));
    try testing.expectEqual(29 * 68, try solve(testing.allocator, "029A", 2));
}

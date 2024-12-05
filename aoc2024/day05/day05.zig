const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const testing = std.testing;

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

pub fn parse_updates(allocator: std.mem.Allocator, bytes: []const u8) !std.ArrayList(u32) {
    var updates = std.ArrayList(u32).init(allocator);
    var tokens = std.mem.tokenizeScalar(u8, bytes, ',');
    while (tokens.next()) |token| {
        const number = try std.fmt.parseInt(u32, token, 10);
        try updates.append(number);
    }

    return updates;
}

pub fn build_masks(allocator: std.mem.Allocator, rules_raw: []const u8) !std.AutoArrayHashMap(u32, u128) {
    var lines_iter = std.mem.splitScalar(u8, rules_raw, '\n');
    var masks = std.AutoArrayHashMap(u32, u128).init(allocator);
    while (lines_iter.next()) |line| {
        var num_iter = std.mem.splitScalar(u8, line, '|');
        const before = num_iter.next();
        const after = num_iter.next();

        if (before == null or after == null) {
            return error.InvalidRule;
        }

        const before_id: u32 = try std.fmt.parseInt(u32, before.?, 10);
        const after_id: u32 = try std.fmt.parseInt(u32, after.?, 10);

        const entry = try masks.getOrPut(after_id);
        const m: u128 = 1;
        if (entry.found_existing) {
            entry.value_ptr.* |= (m << @intCast(before_id));
        } else {
            entry.value_ptr.* = (m << @intCast(before_id));
        }
    }
    return masks;
}

pub fn is_valid(masks: *std.AutoArrayHashMap(u32, u128), updates: *const std.ArrayList(u32)) bool {
    var history_mask: u128 = 0;
    for (updates.items) |id| {
        const m: u128 = 1;

        if (masks.get(id)) |mask| {
            history_mask |= mask;
        }

        if (history_mask & (m << @intCast(id)) != 0) {
            return false;
        }
    }

    return true;
}

const Context = struct {
    masks: *std.AutoArrayHashMap(u32, u128),
};

pub fn sort_fn(ctx: Context, a: u32, b: u32) bool {
    if (ctx.masks.get(b)) |mask| {
        const m: u128 = 1;
        if (mask & (m << @intCast(a)) > 0) {
            return true;
        }
    }
    return false;
}

pub fn correct_pages(masks: *std.AutoArrayHashMap(u32, u128), updates: *const std.ArrayList(u32)) void {
    std.mem.sort(u32, updates.items, Context{ .masks = masks }, sort_fn);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var chunks = std.mem.splitSequence(u8, buff, "\n\n");

    const rules = chunks.next().?;
    var masks = try build_masks(allocator, rules);
    defer masks.deinit();

    const updates_raw = chunks.next().?;
    var lines = std.mem.splitScalar(u8, updates_raw, '\n');

    var part1_sum: u32 = 0;
    var part2_sum: u32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        const updates = try parse_updates(allocator, line);
        defer updates.deinit();

        if (is_valid(&masks, &updates)) {
            part1_sum += updates.items[updates.items.len / 2];
        } else {
            correct_pages(&masks, &updates);
            if (is_valid(&masks, &updates)) {
                part2_sum += updates.items[updates.items.len / 2];
            }
        }
    }

    print("Part 1: {}\n", .{part1_sum});
    print("Part 2: {}\n", .{part2_sum});
}

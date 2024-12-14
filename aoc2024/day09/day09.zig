const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

fn from_usize(c: usize) i64 {
    return @as(i64, @intCast(c));
}

fn from_char(c: u8) usize {
    return @as(usize, @intCast(c)) - @as(usize, @intCast('0'));
}

const Block = struct {
    file_id: ?usize = null,
    file_size: usize,
    start_block: usize,
};

const Disk = struct {
    blocks: std.ArrayList(Block),

    pub fn deinit(self: *Disk) void {
        self.blocks.deinit();
    }
};

fn parse_disk(allocator: std.mem.Allocator, bytes: []const u8) !Disk {
    var blocks = std.ArrayList(Block).init(allocator);
    var block_idx: usize = 0;
    for (0.., bytes) |idx, c| {
        if (c == '\n') break;
        var file_id: ?usize = null;
        if (idx % 2 == 0) file_id = idx / 2;
        const file_size = from_char(c);
        const block = Block{ .file_id = file_id, .file_size = file_size, .start_block = block_idx };
        try blocks.append(block);

        block_idx += file_size;
    }

    return Disk{ .blocks = blocks };
}

fn chunk_sum(file_id: usize, file_size: usize, block_position: usize) usize {
    var sum: usize = 0;
    for (block_position..block_position + file_size) |b| {
        sum += file_id * b;
    }
    return sum;
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

fn part1(disk: *Disk) usize {
    var part1_answer: usize = 0;
    var left: usize = 0;
    var right: usize = disk.blocks.items.len - 1;

    while (left <= right and left < disk.blocks.items.len and right >= 0) {
        var left_blk = &disk.blocks.items[left];
        var right_blk = &disk.blocks.items[right];

        if (left_blk.file_id) |left_file_id| {
            part1_answer += chunk_sum(left_file_id, left_blk.file_size, left_blk.start_block);
            left += 1;
            left_blk = &disk.blocks.items[left];
        }

        if (right_blk.file_id == null) {
            right -= 1;
            right_blk = &disk.blocks.items[right];
        }

        if (left_blk.start_block > right_blk.start_block) break;

        const free_space = left_blk.file_size;
        const needed_space = right_blk.file_size;

        if (needed_space < free_space) {
            part1_answer += chunk_sum(right_blk.file_id.?, needed_space, left_blk.start_block);
            left_blk.file_size -= needed_space;
            left_blk.start_block += needed_space;
            right_blk.file_size = 0;
            right -= 1;
        } else {
            part1_answer += chunk_sum(right_blk.file_id.?, free_space, left_blk.start_block);
            right_blk.file_size -= free_space;
            left += 1;
        }
    }
    return part1_answer;
}

fn part2(disk: *Disk) usize {
    var part2_answer: usize = 0;

    var block_offset: usize = 0;
    for (disk.blocks.items) |*f| {
        f.start_block = block_offset;
        block_offset += f.file_size;
    }

    var right = disk.blocks.items.len - 1;
    while (right > 0) {
        var right_blk = &disk.blocks.items[right];

        if (right_blk.file_id == null) {
            right -= 1;
            continue;
        }

        var left: usize = 0;
        while (left < right) {
            var left_blk = &disk.blocks.items[left];
            if (left_blk.file_id == null and left_blk.file_size >= right_blk.file_size) {
                left_blk.file_size -= right_blk.file_size;
                part2_answer += chunk_sum(right_blk.file_id.?, right_blk.file_size, left_blk.start_block);
                left_blk.start_block += right_blk.file_size;
                right_blk.file_id = null;
                break;
            }

            left += 1;
        }
        if (right_blk.file_id != null) {
            part2_answer += chunk_sum(right_blk.file_id.?, right_blk.file_size, right_blk.start_block);
        }

        right -= 1;
    }

    return part2_answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();
    const bytes = try read_file(allocator, "input.txt");
    defer allocator.free(bytes);

    var disk1 = try parse_disk(allocator, bytes);
    defer disk1.deinit();

    var disk2 = try parse_disk(allocator, bytes);
    defer disk2.deinit();

    print("part1 answer: {}\n", .{part1(&disk1)});
    print("part2 answer: {}\n", .{part2(&disk2)});
}

test "simple example" {
    const example = "12345";
    var disk = try parse_disk(testing.allocator, example);
    defer disk.deinit();

    try testing.expectEqual(60, part1(&disk));
}

test "part1 example" {
    const example = "2333133121414131402";
    var disk = try parse_disk(testing.allocator, example);
    defer disk.deinit();

    try testing.expectEqual(1928, part1(&disk));
}

test "part2 example" {
    const example = "2333133121414131402";
    var disk = try parse_disk(testing.allocator, example);
    defer disk.deinit();

    try testing.expectEqual(2858, part2(&disk));
}

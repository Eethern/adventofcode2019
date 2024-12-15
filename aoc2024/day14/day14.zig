const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const Vec2 = @Vector(2, i32);

const Robot = struct {
    pos: Vec2,
    vel: Vec2,

    fn step(self: *Robot, num_steps: usize, grid_size: Vec2) void {
        const n: Vec2 = @splat(@as(i32, @intCast(num_steps)));
        self.pos = @mod((self.pos + self.vel * n), grid_size);
    }

    fn parse_tuple(bytes: []const u8) !Vec2 {
        var tokens_iter = std.mem.splitAny(u8, bytes, "=,");
        _ = tokens_iter.next();
        const x = try std.fmt.parseInt(i32, tokens_iter.next().?, 10);
        const y = try std.fmt.parseInt(i32, tokens_iter.next().?, 10);
        return Vec2{ x, y };
    }

    fn from_bytes(bytes: []const u8) !Robot {
        var pos_vel_raw = std.mem.splitScalar(u8, bytes, ' ');
        const pos_raw = pos_vel_raw.next().?;
        const vel_raw = pos_vel_raw.next().?;

        return Robot{ .pos = try parse_tuple(pos_raw), .vel = try parse_tuple(vel_raw) };
    }
};

fn parse_robots(allocator: std.mem.Allocator, bytes: []const u8) !std.ArrayList(Robot) {
    var lines_iter = std.mem.splitScalar(u8, bytes, '\n');
    var robots = std.ArrayList(Robot).init(allocator);
    while (lines_iter.next()) |line| {
        if (line.len == 0) break;
        try robots.append(try Robot.from_bytes(line));
    }
    return robots;
}

fn count_quadrants(robots: *std.ArrayList(Robot), grid_size: Vec2) usize {
    var quadrants: [4]usize = .{ 0, 0, 0, 0 }; // TL TR BL BR
    const two: Vec2 = @splat(2);
    const half_grid = grid_size / two;
    for (robots.items) |*robot| {
        if (robot.pos[0] < half_grid[0]) {
            if (robot.pos[1] < half_grid[1]) {
                quadrants[0] += 1;
            } else if (robot.pos[1] > half_grid[1]) {
                quadrants[2] += 1;
            }
        } else if (robot.pos[0] > half_grid[0]) {
            if (robot.pos[1] < half_grid[1]) {
                quadrants[1] += 1;
            } else if (robot.pos[1] > half_grid[1]) {
                quadrants[3] += 1;
            }
        }
    }
    return quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
}

fn step_robots(robots: *std.ArrayList(Robot), grid_size: Vec2, steps: usize) void {
    for (robots.items) |*robot| {
        robot.step(steps, grid_size);
    }
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

fn plot_robots(robots: *const std.ArrayList(Robot), grid_size: Vec2) !void {
    const out_file = std.io.getStdOut();
    var grid = std.mem.zeroes([103][101]u8);
    for (robots.items) |*robot| {
        const x = @as(usize, @intCast(robot.pos[0]));
        const y = @as(usize, @intCast(robot.pos[1]));
        grid[y][x] += 1;
    }

    const width = @as(usize, @intCast(grid_size[0]));
    const height = @as(usize, @intCast(grid_size[1]));
    for (0..height) |y| {
        for (0..width) |x| {
            if (grid[y][x] > 0) {
                try out_file.writer().print("##", .{});
            } else {
                try out_file.writer().print("  ", .{});
            }
        }
        try out_file.writer().print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var robots = try parse_robots(allocator, buff);
    defer robots.deinit();

    const grid_size = Vec2{ 101, 103 };
    step_robots(&robots, grid_size, 100);
    const part1_answer = count_quadrants(&robots, grid_size);
    print("Part1: {}\n", .{part1_answer});

    const part2_answer = 7892;
    step_robots(&robots, grid_size, part2_answer - 100);

    print("Part2: {}\n", .{part2_answer});
    print("{s}\n", .{"-" ** (101 * 2)});
    try plot_robots(&robots, grid_size);
}

test "parse_robot" {
    const raw = "p=0,4 v=3,-3";
    const robot = try Robot.from_bytes(raw);

    try testing.expectEqual(0, robot.pos[0]);
    try testing.expectEqual(4, robot.pos[1]);
    try testing.expectEqual(3, robot.vel[0]);
    try testing.expectEqual(-3, robot.vel[1]);
}

test "robot step" {
    var robot = Robot{
        .pos = Vec2{ 2, 4 },
        .vel = Vec2{ 2, -3 },
    };

    const grid_size = Vec2{ 11, 7 };
    robot.step(5, grid_size);

    try testing.expectEqual(Vec2{ 1, 3 }, robot.pos);
}

const EXAMPLE =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;
test "example" {
    var robots = try parse_robots(testing.allocator, EXAMPLE);
    const grid_size = Vec2{ 11, 7 };
    defer robots.deinit();
    step_robots(&robots, grid_size, 100);
    try testing.expectEqual(12, count_quadrants(&robots, grid_size));
}

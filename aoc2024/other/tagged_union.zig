const std = @import("std");
const print = std.debug.print;

const Vector2 = @Vector(2, u32);
const Particle = struct {
    pos: Vector2,
    vel: Vector2,
    ttl: f32,
    geo: union(enum) {
        LINE: struct {
            rot: f32,
            length: f32,
        },
        DOT: struct {},
    },
};

test "union" {
    const line = Particle{
        .pos = Vector2{ 0, 0 },
        .vel = Vector2{ 0, 0 },
        .ttl = 0.0,
        .geo = .{ .LINE = .{ .rot = 0, .length = 1 } },
    };

    const dot = Particle{
        .pos = Vector2{ 0, 0 },
        .vel = Vector2{ 0, 0 },
        .ttl = 0.0,
        .geo = .{ .DOT = .{} },
    };
    print("{}\n", .{dot});
    print("{}\n", .{line});
}

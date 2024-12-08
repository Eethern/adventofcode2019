const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const testing = std.testing;

pub const Renderable = struct {
    ptr: *anyopaque,
    renderFn: *const fn (ptr: *anyopaque) void,

    fn init(ptr: anytype) Renderable {
        const Ptr = @TypeOf(ptr);
        const PtrInfo = @typeInfo(Ptr);

        comptime assert(PtrInfo == .Pointer);
        comptime assert(PtrInfo.Pointer.size == .One);
        comptime assert(@typeInfo(PtrInfo.Pointer.child) == .Struct);

        const gen = struct {
            pub fn renderFn(pointer: *anyopaque) void {
                const self: Ptr = @ptrCast(@alignCast(pointer));
                return PtrInfo.Pointer.child.render(self);
            }
        };

        return .{ .ptr = ptr, .renderFn = gen.renderFn };
    }

    pub fn render(self: Renderable) void {
        return self.renderFn(self.ptr);
    }
};

pub const Renderer = struct {
    renderables: std.ArrayList(Renderable),
    pub fn init(allocator: std.mem.Allocator) !Renderer {
        const items = std.ArrayList(Renderable).init(allocator);
        return Renderer{
            .renderables = items
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.renderables.deinit();
    }

    pub fn add(self: *Renderer, renderable: Renderable) !void {
        try self.renderables.append(renderable);
    }

    pub fn render(self: *const Renderer) void {
        for (self.renderables.items) |r| {
            r.render();
        }
    }
};

test "renderer" {
    const TestRenderable = struct {
        const Self = @This();
        id: u32,
        pub fn render(self: *Self) void {
            print("Renderable {} rendered!\n", .{self.id});
        }
    };

    var test1 = TestRenderable{ .id = 1 };
    var renderer = try Renderer.init(testing.allocator);
    defer renderer.deinit();

    const ren1 = Renderable.init(&test1);
    try renderer.add(ren1);

    renderer.render();
}

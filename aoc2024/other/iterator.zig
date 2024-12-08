const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const testing = std.testing;

pub fn main() void {
    print("Hello world!\n", .{});
}

const Iterator = struct {
    ptr: *anyopaque,
    nextFn: *const fn(ptr: *anyopaque) ?u32,

    pub fn next(self: Iterator) ?u32 {
        return self.nextFn(self.ptr);
    }
};

const Range = struct {
    start: u32 = 0,
    end: u32,
    step: u32 = 1,

    pub fn next(ptr: *anyopaque) ?u32 {
        const self: *Range = @ptrCast(@alignCast(ptr));
        if (self.start >= self.end) return null;
        const result = self.start;
        self.start += self.step;
        return result;
    }

    pub fn iterator(self: *Range) Iterator {
        return Iterator {
            .ptr = self,
            .nextFn = next,
        };
    }
};

const Iterator2 = struct {
    ptr: *anyopaque,
    nextFn: *const fn(ptr: *anyopaque) ?u32,

    fn init(ptr: anytype) Iterator2 {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn nextFn(pointer: *anyopaque) ?u32 {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.next(self);
            }
        };

        return .{
            .ptr = ptr,
            .nextFn = gen.nextFn
        };
    }

    pub fn next(self: Iterator2) ?u32 {
        return self.nextFn(self.ptr);
    }
};

const Range2 = struct {
    start: u32 = 0,
    end: u32,
    step: u32 = 1,

    pub fn next(self: *Range2) ?u32 {
        if (self.start >= self.end) return null;
        const result = self.start;
        self.start += self.step;
        return result;
    }

    pub fn iterator(self: *Range2) Iterator2 {
        return Iterator2.init(self);
    }
};

test "iterator" {
    var range = Range { .end=5 };
    const iter = range.iterator();

    try testing.expectEqual(@as(?u32, 0), iter.next());
    try testing.expectEqual(@as(?u32, 1), iter.next());
    try testing.expectEqual(@as(?u32, 2), iter.next());
    try testing.expectEqual(@as(?u32, 3), iter.next());
    try testing.expectEqual(@as(?u32, 4), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
}

test "iterator2" {
    var range = Range2 { .end=5 };
    const iter = range.iterator();

    try testing.expectEqual(@as(?u32, 0), iter.next());
    try testing.expectEqual(@as(?u32, 1), iter.next());
    try testing.expectEqual(@as(?u32, 2), iter.next());
    try testing.expectEqual(@as(?u32, 3), iter.next());
    try testing.expectEqual(@as(?u32, 4), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
}

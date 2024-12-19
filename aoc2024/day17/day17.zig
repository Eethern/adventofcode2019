const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const print = std.debug.print;

const REG_A: usize = 0;
const REG_B: usize = 1;
const REG_C: usize = 2;

const OpCode = enum(u3) {
    ADV = 0,
    BXL = 1,
    BST = 2,
    JNZ = 3,
    BXC = 4,
    OUT = 5,
    BDV = 6,
    CDV = 7,
};

const ExitCode = enum {
    HALT,
};

const Computer = struct {
    ip: u64 = 0,
    regfile: [3]u64 = .{ 0, 0, 0 },
    program: std.ArrayList(u3),
    outputs: std.ArrayList(u3),

    fn init(allocator: std.mem.Allocator) Computer {
        return Computer{
            .program = std.ArrayList(u3).init(allocator),
            .outputs = std.ArrayList(u3).init(allocator),
        };
    }

    fn deinit(self: *Computer) void {
        self.program.deinit();
        self.outputs.deinit();
    }

    fn reset(self: *Computer) void {
        self.ip = 0;
        self.outputs.clearAndFree();
    }

    fn load_program(self: *Computer, bytes: []const u8) !void {
        self.program.clearAndFree();
        self.outputs.clearAndFree();
        var chunk_it = std.mem.splitSequence(u8, bytes, "\n\n");
        var reg_raw_it = std.mem.splitScalar(u8, chunk_it.next().?, '\n');

        { // registers
            var reg_idx: usize = 0;
            while (reg_raw_it.next()) |reg_line| : (reg_idx += 1) {
                var it = std.mem.splitSequence(u8, reg_line, ": ");
                _ = it.next().?;
                const value = try std.fmt.parseInt(u64, it.next().?, 10);
                self.regfile[reg_idx] = value;
            }
        }

        {
            var it = std.mem.splitScalar(u8, chunk_it.next().?, ' ');
            _ = it.next().?;
            var program_it = std.mem.splitAny(u8, it.next().?, ",\n");
            while (program_it.next()) |op| {
                if (op.len == 0) break;
                try self.program.append(try std.fmt.parseInt(u3, op, 10));
            }
        }
    }

    fn get_combo_value(self: *const Computer, operand: u3) u64 {
        return switch (operand) {
            0, 1, 2, 3 => |n| @as(u64, n),
            4 => self.regfile[REG_A],
            5 => self.regfile[REG_B],
            6 => self.regfile[REG_C],
            7 => unreachable,
        };
    }

    fn run(self: *Computer) !ExitCode {
        while (true) {
            if (self.ip + 1 >= self.program.items.len) {
                return .HALT;
            }

            const op: OpCode = @enumFromInt(self.program.items[self.ip]);
            const operand: u3 = self.program.items[self.ip + 1];
            var has_jumped = false;
            switch (op) {
                .ADV => self.regfile[REG_A] = @divFloor(self.regfile[REG_A], std.math.pow(u64, 2, @as(u64, self.get_combo_value(operand)))),
                .BXL => self.regfile[REG_B] = self.regfile[REG_B] ^ @as(u64, operand),
                .BST => self.regfile[REG_B] = self.get_combo_value(operand) % 8,
                .JNZ => {
                    if (self.regfile[REG_A] != 0) {
                        has_jumped = true;
                        self.ip = @as(u64, operand);
                    }
                },
                .BXC => self.regfile[REG_B] ^= self.regfile[REG_C],
                .OUT => try self.outputs.append(@as(u3, @truncate(self.get_combo_value(operand) % 8))),
                .BDV => self.regfile[REG_B] = @divFloor(self.regfile[REG_A], std.math.pow(u64, 2, self.get_combo_value(operand))),
                .CDV => self.regfile[REG_C] = @divFloor(self.regfile[REG_A], std.math.pow(u64, 2, self.get_combo_value(operand))),
            }
            if (!has_jumped) self.ip += 2;
        }

        return .HALT;
    }
};

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

fn print_comma_joined_array(array: *const std.ArrayList(u3)) void {
    for (0.., array.items) |i, n| {
        print("{}", .{n});
        if (i < array.items.len - 1) {
            print(",", .{});
        }
    }
}
fn outputs_to_number(array: *const std.ArrayList(u3)) u64 {
    var out: u64 = 0;
    for (1.., array.items) |i, byte| {
        out += @as(u64, byte * std.math.pow(u64, 10, (array.items.len - i)));
    }
    return out;
}

fn reverse_hash(allocator: std.mem.Allocator, computer: *Computer) !u64 {
    var values = std.ArrayList(u64).init(allocator);
    defer values.deinit();
    try values.append(0);

    var new_values = std.ArrayList(u64).init(allocator);
    defer new_values.deinit();

    var v1 = &values;
    var v2 = &new_values;

    const program_len = computer.program.items.len;
    for (0..program_len) |i| {
        const target = @as(u64, computer.program.items[program_len - i - 1]);
        v2.clearAndFree();
        for (v1.items) |q| {
            for (0..8) |candidate| {
                const a = (q << 3) + candidate;

                // This is the input programs expression, just flattened.
                const out = ((((a % 8) ^ 3) ^ 5) ^ (a >> @as(u6, @truncate(((a % 8) ^ 3))))) % 8;
                if (out == target) {
                    try v2.append(a);
                }
            }
        }
        const t = v1;
        v1 = v2;
        v2 = t;
    }

    // because of swapping figure out which vector has the quines
    const v = if (program_len % 2 == 0) v1 else v2;
    var part2_answer: u64 = std.math.maxInt(u64);
    for (v.items) |n| {
        part2_answer = @min(part2_answer, n);
    }
    return part2_answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buff = try read_file(allocator, "input.txt");
    defer allocator.free(buff);

    var computer = Computer.init(allocator);
    defer computer.deinit();
    try computer.load_program(buff);
    _ = try computer.run();

    print("Part1: ", .{});
    print_comma_joined_array(&computer.outputs);
    print("\n", .{});

    const part2_answer = try reverse_hash(allocator, &computer);
    print("Part2: {}\n", .{part2_answer});
}

const EXAMPLE =
    \\Register A: 729
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,1,5,4,3,0
;

test "example" {
    var computer = Computer.init(testing.allocator);
    try computer.load_program(EXAMPLE);
    defer computer.deinit();

    try testing.expectEqual(729, computer.regfile[REG_A]);
    try testing.expectEqual(0, computer.regfile[REG_B]);
    try testing.expectEqual(0, computer.regfile[REG_C]);

    try testing.expectEqual(6, computer.program.items.len);
    try testing.expectEqual(0, computer.program.items[0]);
    try testing.expectEqual(1, computer.program.items[1]);
    try testing.expectEqual(5, computer.program.items[2]);
    try testing.expectEqual(4, computer.program.items[3]);
    try testing.expectEqual(3, computer.program.items[4]);
    try testing.expectEqual(0, computer.program.items[5]);

    try testing.expectEqual(.HALT, try computer.run());
    try testing.expectEqual(10, computer.outputs.items.len);
    try testing.expectEqual(4635635210, outputs_to_number(&computer.outputs));
}

// If register C contains 9, the program 2,6 would set register B to 1.
test "example_1" {
    const bytes =
        \\Register A: 0
        \\Register B: 0
        \\Register C: 9
        \\
        \\Program: 2,6
    ;
    var computer = Computer.init(testing.allocator);
    try computer.load_program(bytes);
    defer computer.deinit();
    try testing.expectEqual(.HALT, try computer.run());

    try testing.expectEqual(1, computer.regfile[REG_B]);
}

// If register A contains 10, the program 5,0,5,1,5,4 would output 0,1,2.
test "example_2" {
    const bytes =
        \\Register A: 10
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 5,0,5,1,5,4
    ;
    var computer = Computer.init(testing.allocator);
    try computer.load_program(bytes);
    defer computer.deinit();
    try testing.expectEqual(.HALT, try computer.run());

    try testing.expectEqual(0, computer.outputs.items[0]);
    try testing.expectEqual(1, computer.outputs.items[1]);
    try testing.expectEqual(2, computer.outputs.items[2]);
}

// If register A contains 2024, the program 0,1,5,4,3,0 would output 4,2,5,6,7,7,7,7,3,1,0 and leave 0 in register A.
test "example_3" {
    const bytes =
        \\Register A: 2024
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    var computer = Computer.init(testing.allocator);
    try computer.load_program(bytes);
    defer computer.deinit();
    try testing.expectEqual(.HALT, try computer.run());

    try testing.expectEqual(0, computer.regfile[REG_A]);
    try testing.expectEqual(42567777310, outputs_to_number(&computer.outputs));
}

// If register B contains 29, the program 1,7 would set register B to 26.
test "example_4" {
    const bytes =
        \\Register A: 0
        \\Register B: 29
        \\Register C: 0
        \\
        \\Program: 1,7
    ;
    var computer = Computer.init(testing.allocator);
    try computer.load_program(bytes);
    defer computer.deinit();
    try testing.expectEqual(.HALT, try computer.run());

    try testing.expectEqual(26, computer.regfile[REG_B]);
}

// If register B contains 2024 and register C contains 43690, the program 4,0 would set register B to 44354.
test "example_5" {
    const bytes =
        \\Register A: 0
        \\Register B: 2024
        \\Register C: 43690
        \\
        \\Program: 4,0
    ;
    var computer = Computer.init(testing.allocator);
    try computer.load_program(bytes);
    defer computer.deinit();
    try testing.expectEqual(.HALT, try computer.run());

    try testing.expectEqual(44354, computer.regfile[REG_B]);
}

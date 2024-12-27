const std = @import("std");
const testing = std.testing;

const Op = enum {
    XOR,
    AND,
    OR,

    fn from_bytes(bytes: []const u8) !Op {
        if (std.mem.eql(u8, bytes, "OR")) {
            return .OR;
        } else if (std.mem.eql(u8, bytes, "AND")) {
            return .AND;
        } else if (std.mem.eql(u8, bytes, "XOR")) {
            return .XOR;
        }
        return error.UnknownOperation;
    }

    fn compute(self: Op, a: u1, b: u1) u1 {
        return switch (self) {
            .XOR => a ^ b,
            .AND => a & b,
            .OR => a | b,
        };
    }
};

const Gate = struct {
    op: Op,
    inputs: [2]u36,
    output: u36,
    output_name: []const u8,

    fn init_from_bytes(bytes: []const u8) !Gate {
        var part_iter = std.mem.splitScalar(u8, bytes, ' ');
        const input1 = hash_signal(part_iter.next().?);
        const op = try Op.from_bytes(part_iter.next().?);
        const input2 = hash_signal(part_iter.next().?);
        _ = part_iter.next();
        const output_name = part_iter.next().?;
        const output = hash_signal(output_name);

        return Gate{
            .op = op,
            .inputs = .{ input1, input2 },
            .output_name = output_name,
            .output = output,
        };
    }
};

fn hash_signal(signal_name: []const u8) u36 {
    var id: u36 = 0;
    const base = 36;

    for (signal_name) |b| {
        var value: u36 = 0;
        if (std.ascii.isDigit(b)) {
            value = b - '0';
        } else if (std.ascii.isLower(b)) {
            value = b - 'a' + 10;
        } else {
            std.debug.print("WEIRD:{c}\n", .{b});
            unreachable;
        }

        id = id * base + value;
    }
    return id;
}

const MAX_NUM_SIGNALS: usize = std.math.pow(usize, 36, 3);

const Circuit = struct {
    signals: [MAX_NUM_SIGNALS]?u1 = undefined,
    gates: std.AutoHashMap(u36, Gate),

    fn init_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Circuit {
        var circuit = Circuit{
            .gates = std.AutoHashMap(u36, Gate).init(allocator),
        };
        @memset(&circuit.signals, null);

        var chunks_iter = std.mem.splitSequence(u8, bytes, "\n\n");
        var const_iter = std.mem.splitScalar(u8, chunks_iter.next().?, '\n');
        while (const_iter.next()) |line| {
            if (line.len == 0) break;
            var part_iter = std.mem.splitSequence(u8, line, ": ");
            const signal_name = part_iter.next().?;
            const signal_id = hash_signal(signal_name);
            const value = try std.fmt.parseInt(u1, part_iter.next().?, 2);
            circuit.signals[signal_id] = value;
        }

        var gate_iter = std.mem.splitScalar(u8, chunks_iter.next().?, '\n');
        while (gate_iter.next()) |gate_raw| {
            if (gate_raw.len == 0) break;
            const gate = try Gate.init_from_bytes(gate_raw);
            try circuit.gates.put(gate.output, gate);
        }

        return circuit;
    }

    fn deinit(self: *Circuit) void {
        self.gates.deinit();
    }

    fn compute_signal(self: *Circuit, signal: u36) !u1 {
        if (self.signals[signal]) |v| return v;

        if (self.gates.get(signal)) |gate| {
            const a = if (self.signals[gate.inputs[0]]) |v| v else try self.compute_signal(gate.inputs[0]);
            const b = if (self.signals[gate.inputs[1]]) |v| v else try self.compute_signal(gate.inputs[1]);

            self.signals[gate.output] = gate.op.compute(a, b);
            return self.signals[gate.output].?;
        }
        return error.UnknownSignal;
    }

    fn read_output(self: *Circuit, allocator: std.mem.Allocator) !u64 {
        var out: u64 = 0;
        var output_idx: usize = 99;
        var output_name = try std.fmt.allocPrint(allocator, "z{d:0>2}", .{output_idx});
        defer allocator.free(output_name);
        while (output_idx >= 0) {
            output_name = try std.fmt.bufPrint(output_name, "z{d:0>2}", .{output_idx});
            const gate = self.gates.get(hash_signal(output_name));
            if (gate) |g| {
                if (std.mem.startsWith(u8, g.output_name, "z")) {
                    const value = try self.compute_signal(g.output);
                    out = out * 2 + value;
                }
            }
            if (output_idx == 0) break;
            output_idx -= 1;
        }

        return out;
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bytes = try read_file(allocator, "input.txt");
    defer allocator.free(bytes);

    var circuit = try Circuit.init_from_bytes(allocator, bytes);
    defer circuit.deinit();

    const part1_answer = try circuit.read_output(allocator);
    std.debug.print("Part1 answer: {}\n", .{part1_answer});
}

test "hash_signal_name" {
    try testing.expectEqual(0, hash_signal("000"));
    try testing.expectEqual(std.math.pow(u36, 36, 3) - 1, hash_signal("zzz"));
}

const EXAMPLE =
    \\x00: 1
    \\x01: 1
    \\x02: 1
    \\y00: 0
    \\y01: 1
    \\y02: 0
    \\
    \\x00 AND y00 -> z00
    \\x01 XOR y01 -> z01
    \\x02 OR y02 -> z02
;

test "parse_circuit" {
    var circuit = try Circuit.init_from_bytes(testing.allocator, EXAMPLE);
    defer circuit.deinit();

    try testing.expectEqual(1, circuit.signals[hash_signal("x00")]);
    try testing.expectEqual(1, circuit.signals[hash_signal("x01")]);
    try testing.expectEqual(1, circuit.signals[hash_signal("x02")]);
    try testing.expectEqual(0, circuit.signals[hash_signal("y00")]);
    try testing.expectEqual(1, circuit.signals[hash_signal("y01")]);
    try testing.expectEqual(0, circuit.signals[hash_signal("y02")]);
    try testing.expectEqual(null, circuit.signals[hash_signal("z02")]);

    const g1 = circuit.gates.get(hash_signal("z00")).?;
    try testing.expectEqual(.AND, g1.op);
    try testing.expectEqual(hash_signal("x00"), g1.inputs[0]);
    try testing.expectEqual(hash_signal("y00"), g1.inputs[1]);
    try testing.expectEqual(hash_signal("z00"), g1.output);

    const g2 = circuit.gates.get(hash_signal("z01")).?;
    try testing.expectEqual(.XOR, g2.op);
    try testing.expectEqual(hash_signal("x01"), g2.inputs[0]);
    try testing.expectEqual(hash_signal("y01"), g2.inputs[1]);
    try testing.expectEqual(hash_signal("z01"), g2.output);

    const g3 = circuit.gates.get(hash_signal("z02")).?;
    try testing.expectEqual(.OR, g3.op);
    try testing.expectEqual(hash_signal("x02"), g3.inputs[0]);
    try testing.expectEqual(hash_signal("y02"), g3.inputs[1]);
    try testing.expectEqual(hash_signal("z02"), g3.output);
}

test "read_out" {
    var circuit = try Circuit.init_from_bytes(testing.allocator, EXAMPLE);
    defer circuit.deinit();

    const out = try circuit.read_output(testing.allocator);
    try testing.expectEqual(4, out);
}

const LARGE_EXAMPLE =
    \\x00: 1
    \\x01: 0
    \\x02: 1
    \\x03: 1
    \\x04: 0
    \\y00: 1
    \\y01: 1
    \\y02: 1
    \\y03: 1
    \\y04: 1
    \\
    \\ntg XOR fgs -> mjb
    \\y02 OR x01 -> tnw
    \\kwq OR kpj -> z05
    \\x00 OR x03 -> fst
    \\tgd XOR rvg -> z01
    \\vdt OR tnw -> bfw
    \\bfw AND frj -> z10
    \\ffh OR nrd -> bqk
    \\y00 AND y03 -> djm
    \\y03 OR y00 -> psh
    \\bqk OR frj -> z08
    \\tnw OR fst -> frj
    \\gnj AND tgd -> z11
    \\bfw XOR mjb -> z00
    \\x03 OR x00 -> vdt
    \\gnj AND wpb -> z02
    \\x04 AND y00 -> kjc
    \\djm OR pbm -> qhw
    \\nrd AND vdt -> hwm
    \\kjc AND fst -> rvg
    \\y04 OR y02 -> fgs
    \\y01 AND x02 -> pbm
    \\ntg OR kjc -> kwq
    \\psh XOR fgs -> tgd
    \\qhw XOR tgd -> z09
    \\pbm OR djm -> kpj
    \\x03 XOR y03 -> ffh
    \\x00 XOR y04 -> ntg
    \\bfw OR bqk -> z06
    \\nrd XOR fgs -> wpb
    \\frj XOR qhw -> z04
    \\bqk OR frj -> z07
    \\y03 OR x01 -> nrd
    \\hwm AND bqk -> z03
    \\tgd XOR rvg -> z12
    \\tnw OR pbm -> gnj
;

test "read_out_large" {
    var circuit = try Circuit.init_from_bytes(testing.allocator, LARGE_EXAMPLE);
    defer circuit.deinit();

    const out = try circuit.read_output(testing.allocator);
    std.debug.print("{b:0>32}\n", .{out});
    try testing.expectEqual(2024, out);
}

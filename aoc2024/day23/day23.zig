const std = @import("std");
const testing = std.testing;

const Adj = std.AutoHashMap(u16, std.ArrayList(u16));

fn hash_node_name(bytes: []const u8) u16 {
    return (@as(u16, bytes[0]) << 8) + @as(u16, bytes[1]);
}

fn unhash_node_name(name: u16) [2]u8 {
    return .{ @as(u8, @truncate(name >> 8)), @as(u8, @truncate(name)) };
}

const Graph = struct {
    adj: Adj,
    fn from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !Graph {
        var lines_it = std.mem.splitScalar(u8, bytes, '\n');
        var adj = Adj.init(allocator);
        while (lines_it.next()) |line| {
            if (line.len == 0) break;
            var edge_iter = std.mem.splitScalar(u8, line, '-');
            const start = edge_iter.next().?;
            const end = edge_iter.next().?;

            const start_id: u16 = hash_node_name(start);
            const end_id: u16 = hash_node_name(end);

            if (adj.getPtr(start_id)) |entry| {
                try entry.append(end_id);
            } else {
                var adj_list = std.ArrayList(u16).init(allocator);
                try adj_list.append(end_id);
                try adj.put(start_id, adj_list);
            }

            if (adj.getPtr(end_id)) |entry| {
                try entry.append(start_id);
            } else {
                var adj_list = std.ArrayList(u16).init(allocator);
                try adj_list.append(start_id);
                try adj.put(end_id, adj_list);
            }
        }
        return Graph{
            .adj = adj,
        };
    }

    fn deinit(self: *Graph) void {
        var adj_iter = self.adj.iterator();
        while (adj_iter.next()) |*entry| {
            entry.value_ptr.deinit();
        }
        self.adj.deinit();
    }

    fn is_neighbor_of(self: *const Graph, a: u16, b: u16) bool {
        const neighbors = self.adj.get(b);
        if (neighbors == null) return false;
        for (neighbors.?.items) |n| {
            if (a == n) return true;
        }
        return false;
    }
};

const Clique = struct {
    a: u16,
    b: u16,
    c: u16,
    fn perm_abc(self: *const Clique) Clique {
        return self;
    }
    fn hash(self: *const Clique) u64 {
        const a_u64 = @as(u64, @intCast(self.a));
        const b_u64 = @as(u64, @intCast(self.b));
        const c_u64 = @as(u64, @intCast(self.c));
        const sum = a_u64 + b_u64 + c_u64;
        const prod = a_u64 * b_u64 * c_u64;
        return sum + prod;
    }
};

fn find_small_cliques(allocator: std.mem.Allocator, graph: *const Graph) !std.AutoHashMap(u64, Clique) {
    var cliques = std.AutoHashMap(u64, Clique).init(allocator);
    var node_iter = graph.adj.iterator();
    while (node_iter.next()) |*entry| {
        const a = entry.key_ptr.*;
        const src_neighbors = graph.adj.get(a).?;
        for (src_neighbors.items) |b| {
            for (src_neighbors.items) |c| {
                if (graph.is_neighbor_of(c, b)) {
                    const clique = Clique{ .a = a, .b = b, .c = c };
                    try cliques.put(clique.hash(), clique);
                }
            }
        }
    }

    return cliques;
}

fn string_less_than(_: void, lhs: [2]u8, rhs: [2]u8) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}

fn construct_password(allocator: std.mem.Allocator, node_set: *const std.AutoHashMap(u16, void)) !std.ArrayList([2]u8) {
    var names = std.ArrayList([2]u8).init(allocator);

    var node_set_iter = node_set.keyIterator();
    while (node_set_iter.next()) |key| {
        const name = unhash_node_name(key.*);
        try names.append(name);
    }

    std.mem.sort([2]u8, names.items, {}, string_less_than);

    return names;
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

    var graph = try Graph.from_bytes(allocator, bytes);
    defer graph.deinit();

    var small_cliques = try find_small_cliques(allocator, &graph);
    defer small_cliques.deinit();
    var num_t_cliques: u32 = 0;
    var cliques_iter = small_cliques.iterator();
    while (cliques_iter.next()) |*entry| {
        const clique = entry.value_ptr;
        if (unhash_node_name(clique.a)[0] == 't' or
            unhash_node_name(clique.b)[0] == 't' or
            unhash_node_name(clique.c)[0] == 't')
        {
            num_t_cliques += 1;
        }
    }

    std.debug.print("Part1 answer: {}\n", .{num_t_cliques});

    var maximum_clique = try find_maximum_clique(allocator, &graph);
    defer maximum_clique.deinit();
    var password = try construct_password(allocator, &maximum_clique);
    defer password.deinit();
    std.debug.print("Part2 answer: ", .{});
    for (0.., password.items) |i, n| {
        std.debug.print("{s}", .{n});
        if (i < password.items.len - 1) {
            std.debug.print(",", .{});
        }
    }
    std.debug.print("\n", .{});
}

fn intersection(
    allocator: std.mem.Allocator,
    a: *const std.AutoHashMap(u16, void),
    b: *const std.AutoHashMap(u16, void),
) !std.AutoHashMap(u16, void) {
    var out = std.AutoHashMap(u16, void).init(allocator);
    var a_iter = a.keyIterator();
    while (a_iter.next()) |a_key| {
        if (b.contains(a_key.*)) try out.put(a_key.*, undefined);
    }
    return out;
}

// // algorithm BronKerbosch1(R, P, X) is
// //     if P and X are both empty then
// //         report R as a maximal clique
// //     for each vertex v in P do
// //         BronKerbosch1(R ⋃ {v}, P ⋂ N(v), X ⋂ N(v))
// //         P := P \ {v}
// //         X := X ⋃ {v}
fn bron_kerbosch(
    allocator: std.mem.Allocator,
    graph: *const Graph,
    R: *std.AutoHashMap(u16, void),
    P: *std.AutoHashMap(u16, void),
    X: *std.AutoHashMap(u16, void),
    max_clique: *std.AutoHashMap(u16, void),
) !void {
    if (P.count() == 0 and X.count() == 0) {
        // If P and X are both empty, R is a maximal clique. Maybe report it
        if (max_clique.count() < R.count()) {
            max_clique.clearAndFree();
            var r_iter = R.keyIterator();
            while (r_iter.next()) |key| {
                try max_clique.put(key.*, undefined);
            }
            return;
        }
    }

    var P_copy = try P.clone();
    defer P_copy.deinit();
    var P_iter = P_copy.keyIterator();
    while (P_iter.next()) |v| {
        try R.put(v.*, undefined);

        const neighbors = graph.adj.getPtr(v.*).?;
        var N = std.AutoHashMap(u16, void).init(allocator);
        defer N.deinit();
        for (neighbors.items) |n| {
            try N.put(n, undefined);
        }

        // This is stupidly ugly, find a nicer way to manage memory.
        // A nicer way is a bitmask to store these sets. Looping over
        // the full bitmask is likely more efficient than doing the
        // amortized hash lookup, and it's definitely faster than
        // allocating entire new hashmaps.
        var new_P = try intersection(allocator, P, &N);
        var new_X = try intersection(allocator, X, &N);
        try bron_kerbosch(allocator, graph, R, &new_P, &new_X, max_clique);
        new_X.deinit();
        new_P.deinit();

        _ = P.remove(v.*);
        try X.put(v.*, undefined);
        _ = R.remove(v.*);
    }
}

fn find_maximum_clique(allocator: std.mem.Allocator, graph: *const Graph) !std.AutoHashMap(u16, void) {
    var max_clique = std.AutoHashMap(u16, void).init(allocator);
    var R = std.AutoHashMap(u16, void).init(allocator);
    defer R.deinit();
    var P = std.AutoHashMap(u16, void).init(allocator);
    defer P.deinit();

    var graph_iter = graph.adj.keyIterator();
    while (graph_iter.next()) |key| {
        try P.put(key.*, undefined);
    }

    var X = std.AutoHashMap(u16, void).init(allocator);
    defer X.deinit();
    try bron_kerbosch(allocator, graph, &R, &P, &X, &max_clique);

    return max_clique;
}

const EXAMPLE =
    \\kh-tc
    \\qp-kh
    \\de-cg
    \\ka-co
    \\yn-aq
    \\qp-ub
    \\cg-tb
    \\vc-aq
    \\tb-ka
    \\wh-tc
    \\yn-cg
    \\kh-ub
    \\ta-co
    \\de-co
    \\tc-td
    \\tb-wq
    \\wh-td
    \\ta-ka
    \\td-qp
    \\aq-cg
    \\wq-ub
    \\ub-vc
    \\de-ta
    \\wq-aq
    \\wq-vc
    \\wh-yn
    \\ka-de
    \\kh-ta
    \\co-tc
    \\wh-qp
    \\tb-vc
    \\td-yn
;

test "parse" {
    var graph = try Graph.from_bytes(testing.allocator, EXAMPLE);
    defer graph.deinit();

    try testing.expectEqual(16, graph.adj.count());
}

test "find_small_cliques" {
    var graph = try Graph.from_bytes(testing.allocator, EXAMPLE);
    defer graph.deinit();
    var cliques = try find_small_cliques(testing.allocator, &graph);
    defer cliques.deinit();

    try testing.expectEqual(12, cliques.count());
}

test "bron kerbosch" {
    var graph = try Graph.from_bytes(testing.allocator, EXAMPLE);
    defer graph.deinit();
    var maximum_clique = try find_maximum_clique(testing.allocator, &graph);
    defer maximum_clique.deinit();
}

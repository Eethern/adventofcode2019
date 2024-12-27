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
}

// // algorithm BronKerbosch1(R, P, X) is
// //     if P and X are both empty then
// //         report R as a maximal clique
// //     for each vertex v in P do
// //         BronKerbosch1(R ⋃ {v}, P ⋂ N(v), X ⋂ N(v))
// //         P := P \ {v}
// //         X := X ⋃ {v}
// fn bron_kerbosch(
//     graph: *const Graph,
//     R: *std.ArrayList(u16),
//     P: *std.ArrayList(u16),
//     X: *std.ArrayList(u16),
//     cliques: *std.ArrayList(Clique),
// ) !void {
//     if (P.items.len == 0 and X.items.len == 0) {
//         // If P and X are both empty, R is a maximal clique
//         const clique = Clique{
//             .a = if (R.items.len > 0) R.items[0] else 0,
//             .b = if (R.items.len > 1) R.items[1] else 0,
//             .c = if (R.items.len > 2) R.items[2] else 0,
//         };
//         try cliques.append(clique);
//     }

//     for (P.items) |v| {
//         // Temporarily add v to R
//         try R.append(v);

//         // Neighbors of v in the graph
//         const neighbors = graph.adj.get(v).?;

//         // Create new sets for P ∩ neighbors(v) and X ∩ neighbors(v)
//         var newP = try filterIntersect(P, &neighbors);
//         defer newP.deinit();

//         var newX = try filterIntersect(X, &neighbors);
//         defer newX.deinit();

//         // Recurse with updated sets
//         try bron_kerbosch(graph, R, &newP, &newX, cliques);

//         // Undo the addition of v to R
//         _ = R.pop();

//         // Move v from P to X
//         try P.remove(v);
//         try X.append(v);
//     }
// }

// fn filterIntersect(original: *std.ArrayList(u16), neighbors: *const std.ArrayList(u16)) !std.ArrayList(u16) {
//     var filtered = std.ArrayList(u16).init(original.allocator);
//     defer filtered.deinit();
//     for (original.items) |item| {
//         if (std.mem.indexOf(u16, neighbors, item) != null) {
//             try filtered.append(item);
//         }
//     }
//     return filtered;
// }

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

// test "bron kerbosch" {
//     var graph = try Graph.from_bytes(testing.allocator, EXAMPLE);
//     defer graph.deinit();

//     var R = std.ArrayList(u16).init(testing.allocator);
//     defer R.deinit();

//     var P = std.ArrayList(u16).init(testing.allocator);
//     defer P.deinit();

//     var X = std.ArrayList(u16).init(testing.allocator);
//     defer X.deinit();

//     var cliques = std.ArrayList(Clique).init(testing.allocator);
//     defer cliques.deinit();

//     try bron_kerbosch(&graph, &R, &P, &X, &cliques);

//     try testing.expectEqual(1, cliques.items.len);
//     try testing.expectEqual(3, cliques.items[0].a);
//     try testing.expectEqual(4, cliques.items[0].b);
//     try testing.expectEqual(5, cliques.items[0].c);
// }

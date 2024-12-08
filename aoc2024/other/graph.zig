const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

pub fn Graph(comptime NodeValueT: type, comptime EdgeValueT: type) type {
    return struct {
        const NodeId = u64;
        const EdgeMap = std.AutoHashMap(NodeId, EdgeValueT);
        const Node = struct {
            id: NodeId,
            value: NodeValueT,
            edge_map: EdgeMap,
        };

        const NodeMap = std.AutoHashMap(NodeId, Node);

        const Self = @This();

        allocator: std.mem.Allocator,
        node_map: NodeMap,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self {
                .allocator = allocator,
                .node_map = std.AutoHashMap(NodeId, Node).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.node_map.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.edge_map.deinit();
            }
            self.node_map.deinit();
        }

        pub fn add_node(self: *Self, node_id: NodeId, node_value: NodeValueT) !void {
            if (self.node_map.getPtr(node_id)) |node| {
                node.value = node_value;
                return;
            }
            const node = Node {
                .id = node_id,
                .value = node_value,
                .edge_map = std.AutoHashMap(NodeId, EdgeValueT).init(self.allocator),
            };
            try self.node_map.put(node_id, node);
        }

        pub fn add_edge(self: *Self, src: NodeId, dest: NodeId, value: EdgeValueT) !void {
            if (!self.node_map.contains(src) or !self.node_map.contains(dest)) {
                return error.NodeNotFound;
            }
            if (self.node_map.getPtr(src)) |src_node| {
                try src_node.edge_map.put(dest, value);
            } else {
                return error.NodeNotFound;
            }
        }

        pub fn get_node(self: *Self, node_id: NodeId) ?*const NodeValueT {
            if (self.node_map.get(node_id)) |node| {
                return &node.value;
            }
            return null;
        }

        pub fn get_edge(self: *Self, src_node_id: NodeId, dest_node_id: NodeId) ?*EdgeValueT {
            if (self.node_map.getPtr(src_node_id)) |src_node| {
                return src_node.edge_map.getPtr(dest_node_id);
            }
            return null;
        }
    };
}


test "graph test" {
    var graph = try Graph(u32, u32).init(testing.allocator);
    defer graph.deinit();

    // 1 <- 2 <- 3

    try graph.add_node(1, 1);
    try graph.add_node(2, 2);
    try graph.add_node(3, 3);

    try graph.add_edge(2, 1, 4);
    try graph.add_edge(3, 2, 5);

    try testing.expectEqual(1, graph.get_node(1).?.*);
    try testing.expectEqual(2, graph.get_node(2).?.*);
    try testing.expectEqual(3, graph.get_node(3).?.*);
    try testing.expectEqual(null, graph.get_node(4));
    try testing.expectEqual(4, graph.get_edge(2, 1).?.*);
    try testing.expectEqual(5, graph.get_edge(3, 2).?.*);
    try testing.expectEqual(null, graph.get_edge(1, 3));
    try testing.expectEqual(null, graph.get_edge(1, 2));
    try testing.expectEqual(null, graph.get_edge(5, 1));

    try testing.expectError(error.NodeNotFound, graph.add_edge(5, 6, 100));
    try testing.expectError(error.NodeNotFound, graph.add_edge(1, 5, 100));
}

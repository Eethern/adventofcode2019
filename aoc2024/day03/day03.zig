const print = std.debug.print;
const std = @import("std");

const input = @embedFile("input.txt");

const Literal = union(enum) { void, int: i64 };

const TokenType = enum {
    MUL,
    LEFT_PAREN,
    RIGHT_PAREN,
    COMMA,
    NUMBER,
    SPACE,
    DONT,
    DO,
    OTHER,
};

const Token = struct {
    ty: TokenType,
    lexeme: []const u8,
    literal: Literal,

    pub fn print(self: Token) void {
        switch (self.literal) {
            .void => std.debug.print("{s}\n", .{@tagName(self.ty)}),
            .int => |value| std.debug.print("({s}: {d})\n", .{ @tagName(self.ty), value }),
        }
    }
};

const Lexer = struct {
    start: usize,
    current: usize,

    tokens: std.ArrayList(Token),
    alloc: std.mem.Allocator,

    source: []const u8,
    keyword_map: std.StringHashMap(TokenType),

    pub fn init(alloc: std.mem.Allocator) !Lexer {
        return Lexer{
            .source = "",
            .start = 0,
            .current = 0,
            .alloc = alloc,
            .tokens = std.ArrayList(Token).init(alloc),
            .keyword_map = init_keywords(alloc),
        };
    }

    pub fn init_keywords(allocator: std.mem.Allocator) std.StringHashMap(TokenType) {
        var keywords = std.StringHashMap(TokenType).init(allocator);
        keywords.put("mul", TokenType.MUL) catch unreachable;
        keywords.put("don't", TokenType.DONT) catch unreachable;
        keywords.put("do", TokenType.DO) catch unreachable;
        return keywords;
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit();
        self.keyword_map.deinit();
    }

    pub fn is_at_end(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    pub fn scan_tokens(self: *Lexer) !std.ArrayList(Token) {
        while (!self.is_at_end()) {
            self.start = self.current;
            try self.scan_token();
        }
        return self.tokens;
    }

    pub fn add_token(self: *Lexer, token_type: TokenType, literal: Literal) !void {
        const token = Token{ .ty = token_type, .literal = literal, .lexeme = self.source[self.start..self.current] };
        try self.tokens.append(token);
    }

    pub fn next(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    pub fn peek(self: *Lexer) u8 {
        return self.source[self.current];
    }

    pub fn number(self: *Lexer) !void {
        while (std.ascii.isDigit(self.peek())) {
            _ = self.next();
        }

        const int = try std.fmt.parseInt(i64, self.source[self.start..self.current], 10);
        try self.add_token(TokenType.NUMBER, Literal{ .int = int });
    }

    pub fn identifier(self: *Lexer) !void {
        var size: usize = 0;
        var c = self.source[self.start];
        while (std.ascii.isAlphanumeric(c) or c == '\'') {
            size += 1;
            c = self.source[self.start + size];
        }

        const keyword = self.keyword_map.get(self.source[self.start .. self.start + size]);
        if (keyword) |value| {
            self.current += size - 1;
            try self.add_token(value, Literal{ .void = {} });
        } else {
            self.start += 1;
        }
    }

    pub fn scan_token(self: *Lexer) !void {
        const c = self.next();
        switch (c) {
            '(' => try self.add_token(TokenType.LEFT_PAREN, Literal{ .void = {} }),
            ')' => try self.add_token(TokenType.RIGHT_PAREN, Literal{ .void = {} }),
            ',' => try self.add_token(TokenType.COMMA, Literal{ .void = {} }),
            ' ' => try self.add_token(TokenType.SPACE, Literal{ .void = {} }),
            'A'...'Z', 'a'...'z', '_' => try self.identifier(),
            '0'...'9' => try self.number(),
            else => try self.add_token(TokenType.OTHER, Literal{ .void = {} }),
        }
    }
};

const Parser = struct {
    tokens: std.ArrayList(Token),
    index: usize,

    pub fn parse_mul_expression(self: *Parser) !i64 {
        try self.expect_token(.MUL);
        try self.expect_token(.LEFT_PAREN);
        const x = try self.parse_number();
        try self.expect_token(.COMMA);
        const y = try self.parse_number();
        try self.expect_token(.RIGHT_PAREN);
        return x * y;
    }

    pub fn parse_number(self: *Parser) !i64 {
        if (self.next_token()) |token| {
            if (token.ty != .NUMBER) {
                return error.ExpectedNumber;
            }
            return token.literal.int;
        }
        return error.ExpectedNumber;
    }

    pub fn expect_token(self: *Parser, expected: TokenType) !void {
        if (self.next_token()) |token| {
            if (token.ty != expected) {
                return error.ExpectedToken;
            }
            return;
        }
        return error.ExpectedToken;
    }

    pub fn next_token(self: *Parser) ?Token {
        if (self.index >= self.tokens.items.len) return null;
        const token = self.tokens.items[self.index];
        self.index += 1;
        return token;
    }

    pub fn peek_token(self: *Parser) ?Token {
        if (self.index >= self.tokens.items.len) return null;
        return self.tokens.items[self.index];
    }
};

fn evaluate_conditionals(allocator: std.mem.Allocator, source: []const u8) !i64 {
    var lexer = try Lexer.init(allocator);
    defer lexer.deinit();
    lexer.source = source;
    const tokens = try lexer.scan_tokens();
    var parser = Parser{ .tokens = tokens, .index = 0 };

    var sum: i64 = 0;
    var mul_enabled = true;
    while (parser.peek_token()) |token| {
        switch (token.ty) {
            TokenType.MUL => {
                const idx = parser.index;
                if (parser.parse_mul_expression()) |value| {
                    if (mul_enabled) {
                        sum += value;
                    }
                    continue;
                } else |_| {
                    parser.index = idx;
                }
            },
            TokenType.DO => mul_enabled = true,
            TokenType.DONT => mul_enabled = false,
            else => {},
        }

        parser.index += 1;
    }
    return sum;
}
fn evaluate(allocator: std.mem.Allocator, source: []const u8) !i64 {
    var lexer = try Lexer.init(allocator);
    defer lexer.deinit();
    lexer.source = source;
    const tokens = try lexer.scan_tokens();
    var parser = Parser{ .tokens = tokens, .index = 0 };

    var sum: i64 = 0;
    while (parser.peek_token()) |token| {
        switch (token.ty) {
            TokenType.MUL => {
                const idx = parser.index;
                if (parser.parse_mul_expression()) |value| {
                    sum += value;
                    continue;
                } else |_| {
                    parser.index = idx;
                }
            },
            else => {},
        }

        parser.index += 1;
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("Part1: {}\n", .{try evaluate(allocator, input)});
    print("Part2: {}\n", .{try evaluate_conditionals(allocator, input)});
}

test "examples" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expectEqual(8, try evaluate(allocator, "mul(2,4)"));
    try std.testing.expectEqual(161, try evaluate(allocator, "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"));
    try std.testing.expectEqual(8, try evaluate(allocator, "mul mul(2,4)"));
    try std.testing.expectEqual(0, try evaluate(allocator, "mul(2,4]"));
    try std.testing.expectEqual(2024, try evaluate(allocator, "mul(44,46)"));
    try std.testing.expectEqual(492, try evaluate(allocator, "mul(123,4)"));
    try std.testing.expectEqual(0, try evaluate(allocator, "mul(4*"));
    try std.testing.expectEqual(0, try evaluate(allocator, "mul(6,9!"));
    try std.testing.expectEqual(0, try evaluate(allocator, "?(12,34)"));
    try std.testing.expectEqual(0, try evaluate(allocator, "mul ( 2 , 4 )"));
    try std.testing.expectEqual(0, try evaluate(allocator, "muaaaaal(1,1)"));
    try std.testing.expectEqual(0, try evaluate(allocator, "why(1,1)"));
    try std.testing.expectEqual(2, try evaluate(allocator, "mul(1,1)\nmul(1,1)"));
    try std.testing.expectEqual(21 * 37, try evaluate(allocator, "don't()do\n()mul(21,37)"));
    try std.testing.expectEqual(0, try evaluate(allocator, "mul(215,630/')"));

    try std.testing.expectEqual(48, try evaluate_conditionals(allocator, "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"));
}

const std = @import("std");
const lexer = @import("lexer.zig");

// Global allocator for WASM
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// Global state
var global_lexer: ?lexer.Lexer = null;
var global_source: ?[]u8 = null;
var token_buffer: [1024]lexer.Token = undefined;
var token_count: usize = 0;

// Export allocator functions for JavaScript
export fn alloc(size: usize) ?[*]u8 {
    const slice = allocator.alloc(u8, size) catch return null;
    return slice.ptr;
}

export fn dealloc(ptr: [*]u8, size: usize) void {
    allocator.free(ptr[0..size]);
}

// Initialize the lexer with source code
export fn initLexer(source_ptr: [*]const u8, source_len: usize) void {
    // Free previous source if exists
    if (global_source) |src| {
        allocator.free(src);
    }

    // Copy source to managed memory
    const source = allocator.alloc(u8, source_len) catch return;
    @memcpy(source, source_ptr[0..source_len]);
    global_source = source;

    // Initialize lexer
    global_lexer = lexer.Lexer.init(source);
    token_count = 0;
}

// Tokenize all and store in buffer
export fn tokenizeAll() usize {
    if (global_lexer == null) return 0;

    token_count = 0;
    var lex = &global_lexer.?;

    while (token_count < token_buffer.len) {
        const token = lex.nextToken();
        token_buffer[token_count] = token;
        token_count += 1;

        if (token.type == .Eof) break;
    }

    return token_count;
}

// Get token at index
export fn getTokenType(index: usize) u32 {
    if (index >= token_count) return @intFromEnum(lexer.TokenType.Invalid);
    return @intFromEnum(token_buffer[index].type);
}

export fn getTokenStart(index: usize) u32 {
    if (index >= token_count) return 0;
    return token_buffer[index].start;
}

export fn getTokenLength(index: usize) u32 {
    if (index >= token_count) return 0;
    return token_buffer[index].length;
}

// Get the lexeme for a token
export fn getTokenLexeme(index: usize, out_ptr: [*]u8) u32 {
    if (index >= token_count or global_source == null) return 0;

    const token = token_buffer[index];
    const src = global_source.?;

    if (token.start + token.length > src.len) return 0;

    const lexeme = src[token.start .. token.start + token.length];
    @memcpy(out_ptr[0..lexeme.len], lexeme);

    return @intCast(lexeme.len);
}

// Clean up
export fn cleanup() void {
    if (global_source) |src| {
        allocator.free(src);
        global_source = null;
    }
    global_lexer = null;
    token_count = 0;
}

const std = @import("std");

pub const TokenType = enum {
    // Literals
    Number,
    Identifier,

    // Keywords
    If,
    Else,
    While,
    For,
    Fn,
    Let,
    Return,
    True,
    False,

    // Operators
    Plus,
    Minus,
    Star,
    Slash,
    Equal,
    EqualEqual,
    BangEqual,
    Less,
    Greater,
    LessEqual,
    GreaterEqual,

    // Delimiters
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Semicolon,
    Comma,

    // Special
    Eof,
    Invalid,
};

pub const Token = struct {
    type: TokenType,
    start: u32,
    length: u32,
};

pub const Lexer = struct {
    source: []const u8,
    start: u32,
    current: u32,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .start = 0,
            .current = 0,
        };
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd()) {
            return self.makeToken(.Eof);
        }

        const c = self.advance();

        if (isAlpha(c)) return self.identifier();
        if (isDigit(c)) return self.number();

        return switch (c) {
            '(' => self.makeToken(.LeftParen),
            ')' => self.makeToken(.RightParen),
            '{' => self.makeToken(.LeftBrace),
            '}' => self.makeToken(.RightBrace),
            ';' => self.makeToken(.Semicolon),
            ',' => self.makeToken(.Comma),
            '+' => self.makeToken(.Plus),
            '-' => self.makeToken(.Minus),
            '*' => self.makeToken(.Star),
            '/' => self.makeToken(.Slash),
            '=' => if (self.match('=')) self.makeToken(.EqualEqual) else self.makeToken(.Equal),
            '!' => if (self.match('=')) self.makeToken(.BangEqual) else self.makeToken(.Invalid),
            '<' => if (self.match('=')) self.makeToken(.LessEqual) else self.makeToken(.Less),
            '>' => if (self.match('=')) self.makeToken(.GreaterEqual) else self.makeToken(.Greater),
            else => self.makeToken(.Invalid),
        };
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn match(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn skipWhitespace(self: *Lexer) void {
        while (true) {
            if (self.isAtEnd()) return;
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t', '\n' => {
                    _ = self.advance();
                },
                else => return,
            }
        }
    }

    fn makeToken(self: *Lexer, token_type: TokenType) Token {
        return Token{
            .type = token_type,
            .start = self.start,
            .length = self.current - self.start,
        };
    }

    fn number(self: *Lexer) Token {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        // Look for decimal point
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance(); // consume '.'
            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }

        return self.makeToken(.Number);
    }

    fn identifier(self: *Lexer) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) {
            _ = self.advance();
        }
        return self.makeToken(self.identifierType());
    }

    fn identifierType(self: *Lexer) TokenType {
        const lexeme = self.source[self.start..self.current];

        if (std.mem.eql(u8, lexeme, "if")) return .If;
        if (std.mem.eql(u8, lexeme, "else")) return .Else;
        if (std.mem.eql(u8, lexeme, "while")) return .While;
        if (std.mem.eql(u8, lexeme, "for")) return .For;
        if (std.mem.eql(u8, lexeme, "fn")) return .Fn;
        if (std.mem.eql(u8, lexeme, "let")) return .Let;
        if (std.mem.eql(u8, lexeme, "return")) return .Return;
        if (std.mem.eql(u8, lexeme, "true")) return .True;
        if (std.mem.eql(u8, lexeme, "false")) return .False;

        return .Identifier;
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

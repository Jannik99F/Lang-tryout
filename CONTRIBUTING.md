# Contributing to Zig Lexer WASM

Thank you for your interest in contributing! This document provides detailed information about the project architecture and development workflow.

## Project Architecture

### Overview

This project consists of three main components:

1. **Zig Lexer Core** (`src/lexer.zig`) - The tokenization engine
2. **WASM Interface** (`src/main.zig`) - Bridge between Zig and JavaScript
3. **Web Frontend** (`public/`) - User interface and WASM integration

### Data Flow

```
User Input (JavaScript)
    ↓
WASM Module (main.zig)
    ↓
Lexer (lexer.zig)
    ↓
Token Stream
    ↓
JavaScript Display
```

## Development Setup

### 1. Install Zig

The project requires Zig 0.13.0 or later. We recommend using the latest development build for the best WASM support.

**Download the specific version used in development:**
```bash
# Linux x86_64
curl -L "https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.747+493ad58ff.tar.xz" -o zig.tar.xz
tar -xf zig.tar.xz
export PATH=$PATH:$(pwd)/zig-x86_64-linux-0.16.0-dev.747+493ad58ff
```

**Verify installation:**
```bash
zig version
# Should output: 0.16.0-dev.747+493ad58ff (or your version)
```

### 2. Project Dependencies

No external dependencies required! The project uses only Zig's standard library.

### 3. Building for Development

**Quick build:**
```bash
./build.sh
```

**Build with optimizations:**
```bash
zig build -Doptimize=ReleaseFast
cp zig-out/bin/lexer.wasm public/
```

**Debug build:**
```bash
zig build -Doptimize=Debug
cp zig-out/bin/lexer.wasm public/
```

### 4. Testing Locally

```bash
cd public
python3 -m http.server 8000
# Visit http://localhost:8000
```

## Code Structure

### Lexer Implementation (src/lexer.zig)

The lexer uses a simple state machine:

```zig
pub const Lexer = struct {
    source: []const u8,     // Input source code
    start: u32,             // Token start position
    current: u32,           // Current scan position

    pub fn nextToken(self: *Lexer) Token {
        // Main tokenization logic
    }
}
```

**Key functions:**
- `nextToken()` - Get the next token from input
- `skipWhitespace()` - Ignore whitespace and continue
- `number()` - Parse numeric literals
- `identifier()` - Parse identifiers and keywords
- `identifierType()` - Distinguish keywords from identifiers

### WASM Interface (src/main.zig)

This file exports functions to JavaScript:

```zig
export fn initLexer(source_ptr: [*]const u8, source_len: usize) void
export fn tokenizeAll() usize
export fn getTokenType(index: usize) u32
// ... more exports
```

**Memory Management:**
- `alloc()` / `dealloc()` - JavaScript-callable memory management
- Global allocator handles all dynamic memory
- Token buffer stores up to 1024 tokens (configurable)

### Web Frontend (public/)

**JavaScript Architecture:**

```javascript
class LexerWasm {
    // Manages WASM module lifecycle
    async init()              // Load and instantiate WASM
    tokenize(source)          // High-level tokenization API
}

class LexerUI {
    // Manages UI state and user interactions
    handleTokenize()          // Process user input
    displayTokens(tokens)     // Render tokens
}
```

## Adding New Features

### Adding a New Token Type

1. **Update Zig enum** (`src/lexer.zig`):
```zig
pub const TokenType = enum {
    // ... existing types
    MyNewToken,  // Add here
};
```

2. **Update lexer logic** (`src/lexer.zig`):
```zig
pub fn nextToken(self: *Lexer) Token {
    // Add case for new token
    return switch (c) {
        '@' => self.makeToken(.MyNewToken),  // Example
        // ... existing cases
    };
}
```

3. **Update JavaScript** (`public/lexer.js`):
```javascript
const TokenType = {
    // ... existing types
    MyNewToken: 30,  // Add with next available index
};

const TokenTypeNames = [
    // ... existing names
    'MyNewToken',  // Add at same index
];
```

4. **Update CSS** (`public/styles.css`):
```css
.token.mynewtoken {
    color: var(--your-color);
}
```

5. **Test thoroughly** with example code

### Adding New Keywords

Update the `identifierType()` function in `src/lexer.zig`:

```zig
fn identifierType(self: *Lexer) TokenType {
    const lexeme = self.source[self.start..self.current];

    if (std.mem.eql(u8, lexeme, "mynewkeyword")) return .MyNewKeyword;
    // ... existing keywords

    return .Identifier;
}
```

## Build Configuration

### Build Options (build.zig)

```zig
pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,        // WebAssembly target
        .os_tag = .freestanding,    // No OS
    });

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addExecutable(.{
        .name = "lexer",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.entry = .disabled;    // No entry point (library)
    lib.rdynamic = true;      // Export all symbols
}
```

### Optimization Levels

- **Debug**: Full debug info, no optimizations
- **ReleaseSafe**: Optimized with safety checks
- **ReleaseFast**: Maximum speed, no safety checks
- **ReleaseSmall**: Optimize for size

## Testing

### Manual Testing Checklist

- [ ] Test all token types
- [ ] Test edge cases (empty input, single character, etc.)
- [ ] Test large inputs (1000+ tokens)
- [ ] Test invalid input
- [ ] Test on multiple browsers
- [ ] Test on mobile devices

### Example Test Cases

```javascript
// Empty input
""

// Single token
"42"

// All token types
"let x = 42; if (x > 10) { return true; }"

// Edge cases
"3.14159"
"_variable_name"
"====="  // Multiple operators

// Large input
(Generate programmatically)
```

## Performance Considerations

### WASM Optimization

- Keep token buffer size reasonable (currently 1024)
- Minimize memory allocations
- Use fixed-size buffers where possible
- Avoid string operations in hot paths

### JavaScript Optimization

- Batch DOM updates
- Use `requestAnimationFrame` for rendering
- Implement virtual scrolling for large token lists
- Cache WASM module after loading

## Debugging

### Zig Debugging

```bash
# Build with debug info
zig build -Doptimize=Debug

# Check WASM exports
wasm-objdump -x zig-out/bin/lexer.wasm | grep export
```

### JavaScript Debugging

```javascript
// Enable verbose logging
console.log('WASM Memory:', this.memory.buffer.byteLength);
console.log('Token count:', tokenCount);

// Inspect WASM instance
console.dir(this.wasm.exports);
```

## Common Issues

### Build Failures

**Issue:** `zig: command not found`
- Solution: Ensure Zig is in your PATH

**Issue:** `error: unable to build for target`
- Solution: Update to latest Zig version

### Runtime Errors

**Issue:** WASM module fails to load
- Check browser console for errors
- Verify `lexer.wasm` is in `public/` directory
- Ensure web server is serving WASM with correct MIME type

**Issue:** Incorrect tokenization
- Add debug output in Zig code
- Check token boundaries
- Verify character encoding (UTF-8)

## Code Style

### Zig Style

- Follow [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- Use `snake_case` for functions and variables
- Use `PascalCase` for types
- Keep lines under 100 characters
- Add comments for complex logic

### JavaScript Style

- Use ES6+ features
- Prefer `const` over `let`
- Use meaningful variable names
- Add JSDoc comments for public APIs

### CSS Style

- Use CSS custom properties for colors
- Mobile-first responsive design
- Follow BEM naming convention

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with descriptive messages
6. Push to your fork
7. Open a Pull Request

## Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [WebAssembly Specification](https://webassembly.github.io/spec/)
- [MDN WebAssembly Guide](https://developer.mozilla.org/en-US/docs/WebAssembly)

## Questions?

Feel free to open an issue for any questions or suggestions!

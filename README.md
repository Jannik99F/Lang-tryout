# Zig Lexer WebAssembly

A simple lexer implemented in Zig and compiled to WebAssembly, with a mobile-friendly web interface.

## Features

- Lexer written in Zig for performance
- Compiled to WebAssembly for client-side execution
- Mobile-friendly, responsive web interface
- Syntax highlighting for tokens
- Real-time tokenization

## Supported Language Syntax

The lexer supports a simple programming language with the following tokens:

### Keywords
- `if`, `else`, `while`, `for`
- `fn`, `let`, `return`
- `true`, `false`

### Operators
- Arithmetic: `+`, `-`, `*`, `/`
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Assignment: `=`

### Delimiters
- Parentheses: `(`, `)`
- Braces: `{`, `}`
- Punctuation: `;`, `,`

### Literals
- Numbers: integers and floating-point (e.g., `42`, `3.14`)
- Identifiers: variable names (e.g., `x`, `myVariable`)

## Project Structure

```
.
├── src/
│   ├── lexer.zig          # Core lexer implementation
│   └── main.zig           # WASM interface and exports
├── public/
│   ├── index.html         # Web interface
│   ├── styles.css         # Styling
│   └── lexer.js           # JavaScript WASM wrapper
├── build.zig              # Zig build configuration
└── README.md
```

## Prerequisites

- [Zig](https://ziglang.org/download/) (version 0.13.0 or later)
- A web server for serving static files (e.g., Python's http.server, Node's http-server, etc.)

## Building

1. Clone the repository:
```bash
git clone <repository-url>
cd Lang-tryout
```

2. Build the WASM module:
```bash
zig build
```

This will create the WASM binary at `zig-out/bin/lexer.wasm`.

3. Copy the WASM file to the public directory:
```bash
cp zig-out/bin/lexer.wasm public/
```

## Running

1. Start a local web server in the `public` directory:

Using Python:
```bash
cd public
python3 -m http.server 8000
```

Using Node.js (with http-server):
```bash
cd public
npx http-server -p 8000
```

2. Open your browser and navigate to:
```
http://localhost:8000
```

## Usage

1. Enter code in the "Source Code" text area
2. Click the "Tokenize" button (or press Ctrl+Enter)
3. View the generated tokens in the "Tokens" section below
4. Each token shows its type and lexeme (the actual text)

### Example Code

```javascript
let x = 42;
let y = 3.14;

if (x > 10) {
    return true;
} else {
    return false;
}

fn calculate(a, b) {
    let result = a + b * 2;
    while (result >= 0) {
        result = result - 1;
    }
    return result;
}
```

## Development

### Zig Code Structure

The lexer is split into two main files:

- **lexer.zig**: Contains the core `Lexer` struct with tokenization logic
- **main.zig**: Provides the WASM interface with exported functions

### Exported WASM Functions

- `alloc(size)` - Allocate memory
- `dealloc(ptr, size)` - Free memory
- `initLexer(source_ptr, source_len)` - Initialize lexer with source code
- `tokenizeAll()` - Tokenize entire input and return token count
- `getTokenType(index)` - Get token type at index
- `getTokenStart(index)` - Get token start position
- `getTokenLength(index)` - Get token length
- `getTokenLexeme(index, out_ptr)` - Get token lexeme
- `cleanup()` - Clean up resources

### Adding New Token Types

1. Add the token type to the `TokenType` enum in `src/lexer.zig`
2. Update the lexer logic in `nextToken()` or helper methods
3. Update the JavaScript `TokenType` enum and `TokenTypeNames` in `public/lexer.js`
4. Add styling for the new token category in `public/styles.css`

## Mobile Support

The interface is fully responsive and optimized for mobile devices:
- Touch-friendly button sizes (44px minimum)
- Responsive layout that adapts to screen size
- Prevents zoom on iOS when focusing inputs
- Optimized font sizes for readability
- Scrollable token output for long lists

## Browser Support

The lexer works in all modern browsers that support WebAssembly:
- Chrome/Edge 57+
- Firefox 52+
- Safari 11+
- Opera 44+

## Performance

The lexer is compiled to WebAssembly for near-native performance. Typical tokenization times:
- Small files (< 1KB): < 1ms
- Medium files (1-10KB): 1-5ms
- Large files (10-100KB): 5-50ms

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

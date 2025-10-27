#!/bin/bash

# Build script for Zig Lexer WASM

set -e

echo "Building Zig Lexer to WebAssembly..."

# Check if zig is installed
if ! command -v zig &> /dev/null; then
    echo "Error: Zig is not installed or not in PATH"
    echo "Please install Zig from https://ziglang.org/download/"
    exit 1
fi

# Show Zig version
echo "Using Zig version:"
zig version

# Build the project
echo "Building..."
zig build

# Copy WASM file to public directory
echo "Copying WASM file to public directory..."
mkdir -p public
cp zig-out/bin/lexer.wasm public/

echo "Build complete!"
echo ""
echo "To run the web interface:"
echo "  cd public"
echo "  python3 -m http.server 8000"
echo ""
echo "Then open http://localhost:8000 in your browser"

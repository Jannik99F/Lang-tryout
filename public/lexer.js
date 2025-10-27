// Token type enum - must match Zig enum
const TokenType = {
    Number: 0,
    Identifier: 1,
    If: 2,
    Else: 3,
    While: 4,
    For: 5,
    Fn: 6,
    Let: 7,
    Return: 8,
    True: 9,
    False: 10,
    Plus: 11,
    Minus: 12,
    Star: 13,
    Slash: 14,
    Equal: 15,
    EqualEqual: 16,
    BangEqual: 17,
    Less: 18,
    Greater: 19,
    LessEqual: 20,
    GreaterEqual: 21,
    LeftParen: 22,
    RightParen: 23,
    LeftBrace: 24,
    RightBrace: 25,
    Semicolon: 26,
    Comma: 27,
    Eof: 28,
    Invalid: 29,
};

const TokenTypeNames = [
    'Number', 'Identifier',
    'If', 'Else', 'While', 'For', 'Fn', 'Let', 'Return', 'True', 'False',
    'Plus', 'Minus', 'Star', 'Slash', 'Equal', 'EqualEqual', 'BangEqual',
    'Less', 'Greater', 'LessEqual', 'GreaterEqual',
    'LeftParen', 'RightParen', 'LeftBrace', 'RightBrace', 'Semicolon', 'Comma',
    'Eof', 'Invalid'
];

// Token category for styling
function getTokenCategory(tokenType) {
    if (tokenType >= TokenType.If && tokenType <= TokenType.False) {
        return 'keyword';
    }
    if (tokenType === TokenType.Number) {
        return 'number';
    }
    if (tokenType === TokenType.Identifier) {
        return 'identifier';
    }
    if (tokenType >= TokenType.Plus && tokenType <= TokenType.GreaterEqual) {
        return 'operator';
    }
    if (tokenType >= TokenType.LeftParen && tokenType <= TokenType.Comma) {
        return 'delimiter';
    }
    if (tokenType === TokenType.Invalid) {
        return 'invalid';
    }
    return 'other';
}

class LexerWasm {
    constructor() {
        this.wasm = null;
        this.memory = null;
        this.exports = null;
    }

    async init() {
        try {
            const response = await fetch('lexer.wasm');
            const buffer = await response.arrayBuffer();

            const importObject = {
                env: {
                    memory: new WebAssembly.Memory({ initial: 256 }),
                },
            };

            const result = await WebAssembly.instantiate(buffer, importObject);
            this.wasm = result.instance;
            this.exports = this.wasm.exports;
            this.memory = this.exports.memory;

            return true;
        } catch (error) {
            console.error('Failed to load WASM module:', error);
            return false;
        }
    }

    tokenize(source) {
        if (!this.wasm) {
            throw new Error('WASM module not initialized');
        }

        // Clean up previous state
        this.exports.cleanup();

        // Encode source to UTF-8
        const encoder = new TextEncoder();
        const sourceBytes = encoder.encode(source);

        // Allocate memory for source
        const sourcePtr = this.exports.alloc(sourceBytes.length);
        if (!sourcePtr) {
            throw new Error('Failed to allocate memory for source');
        }

        // Copy source to WASM memory
        const memoryView = new Uint8Array(this.memory.buffer);
        memoryView.set(sourceBytes, sourcePtr);

        // Initialize lexer
        this.exports.initLexer(sourcePtr, sourceBytes.length);

        // Tokenize
        const tokenCount = this.exports.tokenizeAll();

        // Extract tokens
        const tokens = [];
        for (let i = 0; i < tokenCount; i++) {
            const type = this.exports.getTokenType(i);
            const start = this.exports.getTokenStart(i);
            const length = this.exports.getTokenLength(i);

            // Get lexeme
            const lexemePtr = this.exports.alloc(length);
            this.exports.getTokenLexeme(i, lexemePtr);

            const lexemeView = new Uint8Array(this.memory.buffer, lexemePtr, length);
            const decoder = new TextDecoder();
            const lexeme = decoder.decode(lexemeView);

            tokens.push({
                type,
                typeName: TokenTypeNames[type] || 'Unknown',
                lexeme,
                start,
                length,
            });

            this.exports.dealloc(lexemePtr, length);

            // Stop at EOF
            if (type === TokenType.Eof) break;
        }

        // Free source memory
        this.exports.dealloc(sourcePtr, sourceBytes.length);

        return tokens;
    }
}

// UI Controller
class LexerUI {
    constructor() {
        this.lexer = new LexerWasm();
        this.initialized = false;

        this.elements = {
            sourceInput: document.getElementById('sourceInput'),
            tokenizeBtn: document.getElementById('tokenizeBtn'),
            clearBtn: document.getElementById('clearBtn'),
            tokensOutput: document.getElementById('tokensOutput'),
            tokenCount: document.getElementById('tokenCount'),
            loading: document.getElementById('loading'),
        };

        this.setupEventListeners();
        this.loadDefaultExample();
    }

    async init() {
        this.showLoading(true);
        this.initialized = await this.lexer.init();
        this.showLoading(false);

        if (!this.initialized) {
            this.showError('Failed to load WASM module. Please check console for details.');
            this.elements.tokenizeBtn.disabled = true;
        }
    }

    setupEventListeners() {
        this.elements.tokenizeBtn.addEventListener('click', () => this.handleTokenize());
        this.elements.clearBtn.addEventListener('click', () => this.handleClear());

        // Allow Ctrl+Enter to tokenize
        this.elements.sourceInput.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                this.handleTokenize();
            }
        });
    }

    loadDefaultExample() {
        const example = `let x = 42;
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
}`;
        this.elements.sourceInput.value = example;
    }

    handleTokenize() {
        if (!this.initialized) {
            this.showError('WASM module not ready');
            return;
        }

        const source = this.elements.sourceInput.value;
        if (!source.trim()) {
            this.showError('Please enter some code to tokenize');
            return;
        }

        try {
            const tokens = this.lexer.tokenize(source);
            this.displayTokens(tokens);
        } catch (error) {
            console.error('Tokenization error:', error);
            this.showError('Tokenization failed: ' + error.message);
        }
    }

    handleClear() {
        this.elements.sourceInput.value = '';
        this.elements.tokensOutput.innerHTML = '<p class="placeholder">Tokens will appear here after tokenization</p>';
        this.elements.tokenCount.textContent = '0 tokens';
        this.elements.sourceInput.focus();
    }

    displayTokens(tokens) {
        const output = this.elements.tokensOutput;
        output.innerHTML = '';

        // Filter out EOF token for display
        const displayTokens = tokens.filter(t => t.type !== TokenType.Eof);

        if (displayTokens.length === 0) {
            output.innerHTML = '<p class="placeholder">No tokens found</p>';
            this.elements.tokenCount.textContent = '0 tokens';
            return;
        }

        displayTokens.forEach(token => {
            const tokenEl = document.createElement('div');
            tokenEl.className = `token ${getTokenCategory(token.type)}`;

            const typeEl = document.createElement('span');
            typeEl.className = 'token-type';
            typeEl.textContent = token.typeName;

            const lexemeEl = document.createElement('span');
            lexemeEl.className = 'token-lexeme';
            lexemeEl.textContent = token.lexeme;

            tokenEl.appendChild(typeEl);
            tokenEl.appendChild(lexemeEl);
            output.appendChild(tokenEl);
        });

        this.elements.tokenCount.textContent = `${displayTokens.length} token${displayTokens.length === 1 ? '' : 's'}`;
    }

    showError(message) {
        const output = this.elements.tokensOutput;
        output.innerHTML = `<p class="placeholder" style="color: var(--error);">${message}</p>`;
    }

    showLoading(show) {
        if (show) {
            this.elements.loading.classList.remove('hidden');
        } else {
            this.elements.loading.classList.add('hidden');
        }
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', async () => {
    const ui = new LexerUI();
    await ui.init();
});

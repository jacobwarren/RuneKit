/// RuneANSI module - ANSI escape code parsing and tokenization
///
/// This module provides comprehensive functionality for parsing ANSI escape sequences
/// commonly found in terminal output. It converts raw strings containing ANSI codes
/// into structured tokens that can be processed by higher-level components, with
/// support for lossless round-trip encoding.
///
/// ## Overview
///
/// The RuneANSI module is designed to handle the complex task of parsing terminal
/// output that contains ANSI escape sequences. These sequences control text styling,
/// cursor positioning, screen clearing, and other terminal behaviors.
///
/// ## Key Features
///
/// - **Complete ANSI Support**: Handles SGR (styling), cursor movement, erase sequences, and OSC commands
/// - **Lossless Round-trip**: Tokens can be encoded back to identical ANSI sequences
/// - **Graceful Error Handling**: Malformed sequences are handled without crashing
/// - **High Performance**: Single-pass parsing with minimal memory allocations
/// - **Type Safety**: Structured tokens prevent common parsing errors
///
/// ## Usage
///
/// ```swift
/// import RuneANSI
///
/// let tokenizer = ANSITokenizer()
///
/// // Parse terminal output with colors and formatting
/// let input = "\u{001B}[1;31mError:\u{001B}[0m Something went wrong"
/// let tokens = tokenizer.tokenize(input)
///
/// // Process tokens
/// for token in tokens {
///     switch token {
///     case .text(let content):
///         print("Text: \(content)")
///     case .sgr(let params):
///         print("Styling: \(params)")
///     default:
///         break
///     }
/// }
///
/// // Round-trip encoding
/// let encoded = tokenizer.encode(tokens)
/// assert(encoded == input) // Perfect round-trip
/// ```
///
/// ## Supported ANSI Sequences
///
/// ### SGR (Select Graphic Rendition)
/// - Basic colors (30-37, 40-47)
/// - 256-color palette (38;5;n, 48;5;n)
/// - RGB colors (38;2;r;g;b, 48;2;r;g;b)
/// - Text attributes (bold, italic, underline, etc.)
///
/// ### Cursor Control
/// - Movement (up, down, left, right)
/// - Positioning (absolute, relative)
/// - Line navigation
///
/// ### Erase Operations
/// - Screen clearing (partial, full)
/// - Line clearing (partial, full)
///
/// ### OSC (Operating System Commands)
/// - Window title setting
/// - Icon name setting
/// - Custom commands
///
/// ## Error Handling
///
/// The module gracefully handles various error conditions:
/// - Incomplete sequences at end of input
/// - Invalid parameters in CSI sequences
/// - Unterminated OSC sequences
/// - Unknown escape sequences
///
/// Malformed sequences are typically converted to `.control()` tokens or treated
/// as plain text, ensuring that parsing never fails catastrophically.
///
/// ## Performance Considerations
///
/// The tokenizer is optimized for processing large terminal outputs efficiently:
/// - Single-pass parsing algorithm
/// - Minimal string allocations
/// - Efficient character-by-character processing
/// - No regular expressions (for better performance)
///
/// ## Thread Safety
///
/// All types in this module are value types and are inherently thread-safe.
/// Multiple threads can safely use separate instances of `ANSITokenizer`
/// concurrently.

// Re-export main types for convenience
// Note: Swift doesn't support @_exported import for individual types
// Types are automatically available when importing the module

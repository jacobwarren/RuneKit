/// RuneANSI module - ANSI escape code parsing and tokenization
/// 
/// This module provides functionality for parsing ANSI escape sequences
/// commonly found in terminal output. It converts raw strings containing
/// ANSI codes into structured tokens that can be processed by higher-level
/// components.
///
/// Key features:
/// - Tokenization of ANSI escape sequences
/// - Support for SGR (styling) codes
/// - Cursor movement and erase commands
/// - Preservation of original text semantics

// Re-export main types for convenience
// Note: Swift doesn't support @_exported import for individual types
// Types are automatically available when importing the module

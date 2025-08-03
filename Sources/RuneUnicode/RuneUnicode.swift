/// RuneUnicode module - Unicode width calculations and text processing
/// 
/// This module provides functionality for accurately calculating the display
/// width of Unicode strings in terminal environments. It handles complex
/// cases like emoji, CJK characters, combining marks, and zero-width joiners.
///
/// Key features:
/// - Display width calculation for any Unicode string
/// - Support for emoji (including complex sequences)
/// - CJK character width handling
/// - Zero-width character detection
/// - Foundation for text wrapping and alignment

// Re-export main types for convenience
// Note: Swift doesn't support @_exported import for individual types
// Types are automatically available when importing the module

/// RuneRenderer module - Terminal frame rendering and ANSI output
///
/// This module provides functionality for efficiently rendering content
/// to terminal displays. It handles ANSI escape sequences, cursor management,
/// and frame-based updates with diff optimization.
///
/// Key features:
/// - Actor-based thread-safe rendering
/// - ANSI escape sequence generation
/// - Cursor position management
/// - Screen clearing and frame swapping
/// - Integration with ANSI tokenization

// Re-export main types for convenience
// Note: Swift doesn't support @_exported import for individual types
// Types are automatically available when importing the module

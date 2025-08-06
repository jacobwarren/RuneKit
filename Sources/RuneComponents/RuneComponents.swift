// Re-export main types for convenience
@_exported import RuneLayout
@_exported import RuneANSI

/// RuneComponents module - UI components for terminal interfaces
///
/// This module provides a collection of reusable UI components for building
/// terminal-based user interfaces. Components handle their own rendering
/// within provided layout rectangles.
///
/// ## Components
/// - `Component`: Base protocol for all UI components
/// - `Text`: Styled text component with ANSI support
/// - `Box`: Container component with borders and layout
/// - `BoxLayoutResult`: Layout calculation result
///
/// ## Utilities
/// - Float extensions for terminal coordinate conversion
/// - ANSIColor extensions for color sequence generation
///
/// Key features:
/// - Text rendering with wrapping support
/// - Box containers with border styles
/// - Layout-aware component rendering
/// - Integration with layout and renderer modules
public enum RuneComponents {}

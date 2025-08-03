/// Represents different types of ANSI escape sequence tokens
public enum ANSIToken: Equatable {
    /// Plain text content without any ANSI codes
    case text(String)
    
    /// SGR (Select Graphic Rendition) codes for styling
    /// Examples: [31] for red, [1] for bold, [0] for reset
    case sgr([Int])
    
    /// Cursor movement sequences
    /// Examples: [3, "A"] for up 3 lines, [5, "C"] for right 5 columns
    case cursor(Int, String)
    
    /// Erase sequences
    /// Examples: [0, "J"] for erase from cursor to end of screen
    case erase(Int, String)
    
    /// Other control sequences that don't fit above categories
    case control(String)
}

/// Protocol for types that can tokenize ANSI escape sequences
public protocol ANSITokenizing {
    /// Tokenizes ANSI escape sequences from input string
    /// - Parameter input: Raw terminal string with ANSI codes
    /// - Returns: Array of tokens preserving original semantics
    func tokenize(_ input: String) -> [ANSIToken]
}

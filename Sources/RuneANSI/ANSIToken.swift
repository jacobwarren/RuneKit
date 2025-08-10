/// Represents different types of ANSI escape sequence tokens
///
/// This enum provides a structured representation of ANSI escape sequences
/// found in terminal output. Each case corresponds to a specific type of
/// terminal control sequence with its associated parameters.
///
/// ## Token Types
///
/// - ``text(_:)``: Plain text without escape sequences
/// - ``sgr(_:)``: Styling and color codes
/// - ``cursor(_:_:)``: Cursor positioning commands
/// - ``erase(_:_:)``: Screen and line clearing commands
/// - ``osc(_:_:)``: Operating system commands (like title setting)
/// - ``control(_:)``: Other escape sequences not covered above

/// Terminator used in OSC sequences
public enum OSCTerminator: Equatable {
    case bel
    case st
}

/// - ``oscExt(_:_::_:)``: OSC with explicit terminator preservation (BEL vs ST)
public enum ANSIToken: Equatable {
    /// Plain text content without any ANSI codes
    ///
    /// This represents regular text that should be displayed as-is without
    /// any special terminal processing.
    ///
    /// - Parameter content: The text content to display
    ///
    /// ## Example
    /// ```swift
    /// let token = ANSIToken.text("Hello World")
    /// ```
    case text(String)

    /// SGR (Select Graphic Rendition) codes for styling and colors
    ///
    /// These codes control text appearance including colors, bold, italic,
    /// underline, and other visual attributes.
    ///
    /// - Parameter parameters: Array of SGR parameter codes
    ///
    /// ## Common Parameters
    /// - `[0]`: Reset all attributes
    /// - `[1]`: Bold
    /// - `[3]`: Italic
    /// - `[4]`: Underline
    /// - `[30-37]`: Foreground colors (black to white)
    /// - `[40-47]`: Background colors
    /// - `[38, 5, n]`: 256-color foreground (n = 0-255)
    /// - `[38, 2, r, g, b]`: RGB foreground color
    ///
    /// ## Examples
    /// ```swift
    /// let red = ANSIToken.sgr([31])           // Red text
    /// let bold = ANSIToken.sgr([1])           // Bold text
    /// let boldRed = ANSIToken.sgr([1, 31])    // Bold red text
    /// let reset = ANSIToken.sgr([0])          // Reset formatting
    /// let rgb = ANSIToken.sgr([38, 2, 255, 0, 0]) // RGB red
    /// ```
    case sgr([Int])

    /// Cursor movement and positioning sequences
    ///
    /// These sequences control cursor position within the terminal.
    ///
    /// - Parameters:
    ///   - count: Number of positions/lines to move (default 1 if omitted)
    ///   - direction: Single character indicating direction
    ///
    /// ## Direction Characters
    /// - `"A"`: Up
    /// - `"B"`: Down
    /// - `"C"`: Right (forward)
    /// - `"D"`: Left (backward)
    /// - `"E"`: Next line (beginning)
    /// - `"F"`: Previous line (beginning)
    /// - `"G"`: Column position (absolute)
    /// - `"H"`: Position (row, column)
    ///
    /// ## Examples
    /// ```swift
    /// let up3 = ANSIToken.cursor(3, "A")      // Move up 3 lines
    /// let right5 = ANSIToken.cursor(5, "C")   // Move right 5 columns
    /// let home = ANSIToken.cursor(1, "H")     // Move to home position
    /// ```
    case cursor(Int, String)

    /// Erase sequences for clearing screen or line content
    ///
    /// These sequences clear portions of the terminal display.
    ///
    /// - Parameters:
    ///   - mode: Erase mode (0, 1, or 2)
    ///   - type: Erase type ("J" for display, "K" for line)
    ///
    /// ## Erase Modes
    /// ### For "J" (Erase Display):
    /// - `0`: From cursor to end of screen
    /// - `1`: From beginning of screen to cursor
    /// - `2`: Entire screen
    ///
    /// ### For "K" (Erase Line):
    /// - `0`: From cursor to end of line
    /// - `1`: From beginning of line to cursor
    /// - `2`: Entire line
    ///
    /// ## Examples
    /// ```swift
    /// let clearScreen = ANSIToken.erase(2, "J")    // Clear entire screen
    /// let clearLine = ANSIToken.erase(2, "K")      // Clear entire line
    /// let clearToEnd = ANSIToken.erase(0, "J")     // Clear to end of screen
    /// ```
    case erase(Int, String)

    /// OSC (Operating System Command) sequences
    ///
    /// These sequences send commands to the terminal emulator or operating
    /// system, commonly used for setting window titles and other properties.
    ///
    /// - Parameters:
    ///   - command: OSC command identifier
    ///   - data: Command data/payload
    ///
    /// ## Common Commands
    /// - `"0"`: Set window title and icon name
    /// - `"1"`: Set icon name
    /// - `"2"`: Set window title
    ///
    /// ## Examples
    /// ```swift
    /// let title = ANSIToken.osc("0", "My App")     // Set window title
    /// let icon = ANSIToken.osc("1", "MyApp")       // Set icon name
    /// ```
    case osc(String, String)

    /// Other control sequences not covered by specific cases
    ///
    /// This catch-all case handles escape sequences that don't fit into
    /// the other categories, preserving them for specialized processing.
    ///
    /// - Parameter sequence: The complete escape sequence including ESC character
    ///
    /// ## Example
    /// ```swift
    /// let unknown = ANSIToken.control("\u{001B}[?25h") // Show cursor
    /// ```

    /// Extended OSC token that preserves the original terminator style
    /// - Parameters:
    ///   - command: OSC command identifier (Ps)
    ///   - data: OSC payload (Pt)
    ///   - terminator: Terminator used in the original sequence (.bel or .st)
    case oscExt(String, String, OSCTerminator)

    case control(String)
}

/// Protocol for types that can tokenize ANSI escape sequences
///
/// Conforming types can parse raw terminal strings containing ANSI escape
/// sequences and convert them into structured token arrays for processing.
///
/// ## Implementation Requirements
///
/// Implementations should:
/// - Handle all common ANSI sequence types (SGR, cursor, erase, OSC)
/// - Gracefully recover from malformed sequences
/// - Preserve original text semantics
/// - Process input in a single pass for efficiency
///
/// ## Example Implementation
/// ```swift
/// struct MyTokenizer: ANSITokenizing {
///     func tokenize(_ input: String) -> [ANSIToken] {
///         // Parse input and return tokens
///     }
/// }
/// ```
public protocol ANSITokenizing {
    /// Tokenizes ANSI escape sequences from input string
    ///
    /// This method parses the input string and identifies ANSI escape sequences,
    /// converting them into structured tokens while preserving plain text content.
    ///
    /// - Parameter input: Raw terminal string that may contain ANSI codes
    /// - Returns: Array of tokens representing the parsed content
    ///
    /// ## Behavior
    /// - Plain text is preserved in `.text()` tokens
    /// - Valid ANSI sequences become typed tokens (`.sgr()`, `.cursor()`, etc.)
    /// - Malformed sequences are handled gracefully (usually as `.control()` or `.text()`)
    /// - Empty input returns empty array
    ///
    /// ## Example
    /// ```swift
    /// let tokenizer = ANSITokenizer()
    /// let tokens = tokenizer.tokenize("\u{001B}[31mRed\u{001B}[0m")
    /// // Returns: [.sgr([31]), .text("Red"), .sgr([0])]
    /// ```
    func tokenize(_ input: String) -> [ANSIToken]
}

/// Protocol for types that can encode ANSI tokens back to escape sequences
///
/// Conforming types can convert structured ANSI tokens back into their
/// original string representation, enabling lossless round-trip processing.
///
/// ## Implementation Requirements
///
/// Implementations should:
/// - Generate valid ANSI escape sequences for all token types
/// - Preserve exact formatting for round-trip compatibility
/// - Handle edge cases (empty parameters, default values)
/// - Maintain performance for large token arrays
///
/// ## Example Implementation
/// ```swift
/// struct MyEncoder: ANSIEncoding {
///     func encode(_ tokens: [ANSIToken]) -> String {
///         // Convert tokens back to ANSI sequences
///     }
/// }
/// ```
public protocol ANSIEncoding {
    /// Encodes ANSI tokens back to their original escape sequence representation
    ///
    /// This method converts structured tokens back into a string containing
    /// the equivalent ANSI escape sequences, enabling round-trip processing.
    ///
    /// - Parameter tokens: Array of ANSI tokens to encode
    /// - Returns: String containing the encoded ANSI escape sequences
    ///
    /// ## Behavior
    /// - `.text()` tokens are output as-is
    /// - Typed tokens become their corresponding ANSI sequences
    /// - Empty token array returns empty string
    /// - Maintains exact formatting for round-trip compatibility
    ///
    /// ## Example

    /// ```swift
    /// let tokenizer = ANSITokenizer()
    /// let tokens: [ANSIToken] = [.sgr([31]), .text("Red"), .sgr([0])]
    /// let encoded = tokenizer.encode(tokens)
    /// // Returns: "\u{001B}[31mRed\u{001B}[0m"
    /// ```
    func encode(_ tokens: [ANSIToken]) -> String
}

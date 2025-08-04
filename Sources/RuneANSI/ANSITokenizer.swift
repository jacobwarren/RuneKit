/// ANSI escape sequence tokenizer with round-trip encoding support
///
/// This tokenizer parses ANSI escape sequences commonly found in terminal output
/// and converts them into structured tokens that can be processed by higher-level
/// components. It supports lossless round-trip encoding, meaning tokens can be
/// converted back to their original ANSI sequence representation.
///
/// ## Supported Sequences
///
/// - **SGR (Select Graphic Rendition)**: Color and styling codes like `\u{001B}[31m` (red)
/// - **Cursor Movement**: Positioning commands like `\u{001B}[3A` (up 3 lines)
/// - **Erase Sequences**: Screen/line clearing like `\u{001B}[2J` (clear screen)
/// - **OSC (Operating System Command)**: Title setting like `\u{001B}]0;Title\u{0007}`
/// - **Control Sequences**: Other escape sequences not covered above
///
/// ## Usage
///
/// ```swift
/// let tokenizer = ANSITokenizer()
///
/// // Parse ANSI sequences
/// let input = "\u{001B}[31mRed Text\u{001B}[0m"
/// let tokens = tokenizer.tokenize(input)
/// // Result: [.sgr([31]), .text("Red Text"), .sgr([0])]
///
/// // Round-trip encoding
/// let encoded = tokenizer.encode(tokens)
/// // Result: "\u{001B}[31mRed Text\u{001B}[0m" (identical to input)
/// ```
///
/// ## Error Handling
///
/// The tokenizer gracefully handles malformed or incomplete sequences:
/// - Incomplete sequences at end of input are treated as plain text
/// - Invalid parameters in CSI sequences result in control tokens
/// - OSC sequences without terminators are treated as plain text
///
/// ## Performance
///
/// The tokenizer is designed for efficiency with single-pass parsing and
/// minimal memory allocations. It can handle large terminal outputs without
/// significant performance degradation.
public struct ANSITokenizer: ANSITokenizing, ANSIEncoding {
    public init() {}

    /// Tokenizes ANSI escape sequences from input string
    /// - Parameter input: Raw terminal string with ANSI codes
    /// - Returns: Array of tokens preserving original semantics
    public func tokenize(_ input: String) -> [ANSIToken] {
        if input.isEmpty {
            return []
        }

        var tokens: [ANSIToken] = []
        var currentIndex = input.startIndex

        while currentIndex < input.endIndex {
            // Look for escape sequence start
            if let escapeIndex = input[currentIndex...].firstIndex(of: "\u{001B}") {
                // Add any text before the escape sequence
                if escapeIndex > currentIndex {
                    let textContent = String(input[currentIndex ..< escapeIndex])
                    tokens.append(.text(textContent))
                }

                // Parse the escape sequence
                if let (token, nextIndex) = parseEscapeSequence(from: input, startingAt: escapeIndex) {
                    tokens.append(token)
                    currentIndex = nextIndex
                } else {
                    // If we can't parse the escape sequence, treat it as text
                    let nextIndex = input.index(after: escapeIndex)
                    let invalidSequence = String(input[escapeIndex ..< nextIndex])
                    tokens.append(.text(invalidSequence))
                    currentIndex = nextIndex
                }
            } else {
                // No more escape sequences, add remaining text
                let remainingText = String(input[currentIndex...])
                tokens.append(.text(remainingText))
                break
            }
        }

        return tokens
    }

    /// Parses an escape sequence starting at the given index
    /// - Parameters:
    ///   - input: The input string containing the escape sequence
    ///   - startIndex: The index of the escape character (\u{001B})
    /// - Returns: A tuple of the parsed token and the index after the sequence, or nil if parsing fails
    private func parseEscapeSequence(
        from input: String,
        startingAt startIndex: String.Index,
        ) -> (ANSIToken, String.Index)? {
        guard startIndex < input.endIndex else { return nil }

        let escapeIndex = input.index(after: startIndex)
        guard escapeIndex < input.endIndex else { return nil }

        let nextChar = input[escapeIndex]

        switch nextChar {
        case "[":
            // CSI (Control Sequence Introducer) - handles SGR, cursor movement, erase
            return parseCSISequence(from: input, startingAt: escapeIndex)
        case "]":
            // OSC (Operating System Command)
            return parseOSCSequence(from: input, startingAt: escapeIndex)
        default:
            // Other escape sequences - treat as control
            let endIndex = input.index(after: escapeIndex)
            let controlSequence = String(input[startIndex ..< endIndex])
            return (.control(controlSequence), endIndex)
        }
    }

    /// Parses a CSI (Control Sequence Introducer) sequence
    /// - Parameters:
    ///   - input: The input string
    ///   - startIndex: The index of the '[' character
    /// - Returns: A tuple of the parsed token and the index after the sequence, or nil if parsing fails
    private func parseCSISequence(
        from input: String,
        startingAt startIndex: String.Index,
        ) -> (ANSIToken, String.Index)? {
        var currentIndex = input.index(after: startIndex) // Skip the '['
        var parameters: [String] = []
        var currentParam = ""

        // Parse parameters and final character
        while currentIndex < input.endIndex {
            let char = input[currentIndex]

            if char.isNumber {
                currentParam.append(char)
            } else if char == ";" {
                parameters.append(currentParam)
                currentParam = ""
            } else if char.isLetter || "ABCDEFGHIJKLMNOPQRSTUVWXYZ@`".contains(char) {
                // Final character found
                if !currentParam.isEmpty {
                    parameters.append(currentParam)
                }

                let finalChar = String(char)
                let nextIndex = input.index(after: currentIndex)

                // Check if we have any invalid parameters (non-numeric)
                let hasInvalidParams = parameters.contains { !$0.isEmpty && Int($0) == nil }

                if hasInvalidParams {
                    // Treat as control sequence if parameters are invalid
                    let escapeIndex = input.index(before: startIndex) // This points to the ESC character
                    let fullSequence = String(input[escapeIndex ..< nextIndex])
                    return (.control(fullSequence), nextIndex)
                }

                // Determine token type based on final character
                switch finalChar {
                case "m":
                    // SGR (Select Graphic Rendition)
                    let intParams = parameters.isEmpty ? [0] : parameters.compactMap { Int($0) }
                    return (.sgr(intParams), nextIndex)
                case "A", "B", "C", "D", "E", "F", "G", "H":
                    // Cursor movement
                    let count = parameters.first.flatMap { Int($0) } ?? 1
                    return (.cursor(count, finalChar), nextIndex)
                case "J", "K":
                    // Erase sequences
                    let mode = parameters.first.flatMap { Int($0) } ?? 0
                    return (.erase(mode, finalChar), nextIndex)
                default:
                    // Other CSI sequences
                    let escapeIndex = input.index(before: startIndex) // This points to the ESC character
                    let fullSequence = String(input[escapeIndex ..< nextIndex])
                    return (.control(fullSequence), nextIndex)
                }
            } else {
                // Invalid character in CSI sequence - add to current parameter and continue
                // This allows us to detect invalid parameters later
                currentParam.append(char)
            }

            currentIndex = input.index(after: currentIndex)
        }

        // If we reach here, the sequence was malformed
        return nil
    }

    /// Parses an OSC (Operating System Command) sequence
    /// - Parameters:
    ///   - input: The input string
    ///   - startIndex: The index of the ']' character
    /// - Returns: A tuple of the parsed token and the index after the sequence, or nil if parsing fails
    private func parseOSCSequence(
        from input: String,
        startingAt startIndex: String.Index,
        ) -> (ANSIToken, String.Index)? {
        var currentIndex = input.index(after: startIndex) // Skip the ']'
        var command = ""
        var data = ""
        var foundSeparator = false

        // Parse OSC sequence until terminator
        while currentIndex < input.endIndex {
            let char = input[currentIndex]

            if char == "\u{0007}" || (char == "\u{001B}" &&
                                        input.index(after: currentIndex) < input.endIndex &&
                                        input[input.index(after: currentIndex)] == "\\"
            ) {
                // Found terminator (BEL or ESC\)
                let nextIndex: String.Index = if char == "\u{0007}" {
                    input.index(after: currentIndex)
                } else {
                    input.index(currentIndex, offsetBy: 2)
                }

                return (.osc(command, data), nextIndex)
            } else if char == ";", !foundSeparator {
                // First semicolon separates command from data
                foundSeparator = true
            } else if foundSeparator {
                data.append(char)
            } else {
                command.append(char)
            }

            currentIndex = input.index(after: currentIndex)
        }

        // If we reach here, the sequence was malformed (no terminator found)
        return nil
    }

    /// Encodes ANSI tokens back to their original escape sequence representation
    /// - Parameter tokens: Array of ANSI tokens to encode
    /// - Returns: String containing the encoded ANSI escape sequences
    public func encode(_ tokens: [ANSIToken]) -> String {
        tokens.map { encodeToken($0) }.joined()
    }

    /// Encodes a single ANSI token back to its escape sequence
    /// - Parameter token: The token to encode
    /// - Returns: String representation of the token
    private func encodeToken(_ token: ANSIToken) -> String {
        switch token {
        case let .text(content):
            return content
        case let .sgr(parameters):
            let paramString = parameters.map { String($0) }.joined(separator: ";")
            return "\u{001B}[\(paramString)m"
        case let .cursor(count, direction):
            if count == 1 {
                return "\u{001B}[\(direction)"
            } else {
                return "\u{001B}[\(count)\(direction)"
            }
        case let .erase(mode, type):
            if mode == 0 {
                return "\u{001B}[\(type)"
            } else {
                return "\u{001B}[\(mode)\(type)"
            }
        case let .osc(command, data):
            return "\u{001B}]\(command);\(data)\u{0007}"
        case let .control(sequence):
            return sequence
        }
    }
}

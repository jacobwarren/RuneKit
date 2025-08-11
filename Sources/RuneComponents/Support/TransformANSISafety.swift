import Foundation
import RuneANSI

/// Shared ANSI-safe transformation utilities for Transform components
///
/// Provides helpers to apply string transformations while preserving ANSI
/// escape sequences by tokenizing, transforming only text tokens, and
/// re-encoding tokens back to strings.
enum TransformANSISafety {
    /// Apply a synchronous transformation safely to a single string.
    /// - Parameters:
    ///   - input: The input string (may contain ANSI sequences)
    ///   - transform: Text-only transformation function
    /// - Returns: Transformed string with ANSI preserved
    static func applySafely(to input: String, transform: (String) -> String) -> String {
        // Fast path: no ANSI sequences
        if !input.contains("\u{001B}[") {
            return transform(input)
        }
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize(input)
        let transformed = tokens.map { token -> ANSIToken in
            if case let .text(segment) = token { return .text(transform(segment)) }
            return token
        }
        return tokenizer.encode(transformed)
    }

    /// Apply a time-based transformation safely to a single string.
    /// - Parameters:
    ///   - input: The input string (may contain ANSI sequences)
    ///   - time: Current timestamp used by transformation
    ///   - transform: Text-only transformation function that accepts time
    /// - Returns: Transformed string with ANSI preserved
    static func applySafely(
        to input: String,
        time: TimeInterval,
        transform: (String, TimeInterval) -> String,
    ) -> String {
        // Fast path: no ANSI sequences
        if !input.contains("\u{001B}[") {
            return transform(input, time)
        }
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize(input)
        let transformed = tokens.map { token -> ANSIToken in
            if case let .text(segment) = token { return .text(transform(segment, time)) }
            return token
        }
        return tokenizer.encode(transformed)
    }
}

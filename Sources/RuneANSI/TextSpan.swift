/// Text span with styling attributes for ANSI-aware text representation
///
/// This module provides the TextSpan structure that represents a contiguous
/// piece of text with consistent styling attributes.

import RuneUnicode

/// A span of text with consistent styling attributes
///
/// TextSpan represents a contiguous piece of text that shares the same
/// styling attributes. This allows for efficient representation and
/// manipulation of styled text.
public struct TextSpan: Equatable, Hashable {
    /// The text content of this span
    public let text: String

    /// The styling attributes applied to this span
    public let attributes: TextAttributes

    /// Initialize a text span
    ///
    /// - Parameters:
    ///   - text: The text content
    ///   - attributes: The styling attributes to apply
    public init(text: String, attributes: TextAttributes) {
        self.text = text
        self.attributes = attributes
    }

    /// Create a plain text span with no styling
    ///
    /// - Parameter text: The text content
    /// - Returns: A text span with default attributes
    public static func plain(_ text: String) -> TextSpan {
        TextSpan(text: text, attributes: TextAttributes())
    }

    /// Check if this span has any styling applied
    public var isPlain: Bool {
        attributes.isDefault
    }

    /// The length of the text content
    public var length: Int {
        text.count
    }

    /// Check if this span is empty
    public var isEmpty: Bool {
        text.isEmpty
    }

    /// Split this span at the specified character index
    ///
    /// This method splits the text span into two parts at the given character
    /// index, preserving the attributes in both resulting spans.
    ///
    /// - Parameter index: The character index at which to split (0-based)
    /// - Returns: A tuple containing the left and right parts
    public func split(at index: Int) -> (left: TextSpan, right: TextSpan) {
        let clampedIndex = max(0, min(index, text.count))

        let leftText = String(text.prefix(clampedIndex))
        let rightText = String(text.dropFirst(clampedIndex))

        let leftSpan = TextSpan(text: leftText, attributes: attributes)
        let rightSpan = TextSpan(text: rightText, attributes: attributes)

        return (left: leftSpan, right: rightSpan)
    }

    /// Split this span at the specified display width position
    ///
    /// This method splits the text span into two parts at the given display width
    /// position, preserving grapheme cluster boundaries and handling wide characters.
    ///
    /// - Parameters:
    ///   - displayWidth: The display width position at which to split (0-based)
    ///   - lastColumnGuard: If true, prevents 2-width characters from being placed at the last column
    /// - Returns: A tuple containing the left and right parts
    public func splitByDisplayWidth(
        at displayWidth: Int,
        lastColumnGuard: Bool = false,
        ) -> (left: TextSpan, right: TextSpan) {
        guard displayWidth > 0 else {
            return (left: TextSpan(text: "", attributes: attributes), right: self)
        }

        var currentWidth = 0
        var splitIndex = 0

        // Iterate through grapheme clusters to find the split point
        for (index, cluster) in text.enumerated() {
            let clusterWidth = Width.displayWidth(of: cluster)

            // Check if adding this cluster would exceed the target width
            if currentWidth + clusterWidth > displayWidth {
                break
            }

            // Check last column guard for 2-width characters
            if lastColumnGuard, clusterWidth == 2, currentWidth + clusterWidth == displayWidth {
                break
            }

            currentWidth += clusterWidth
            splitIndex = index + 1
        }

        let leftText = String(text.prefix(splitIndex))
        let rightText = String(text.dropFirst(splitIndex))

        let leftSpan = TextSpan(text: leftText, attributes: attributes)
        let rightSpan = TextSpan(text: rightText, attributes: attributes)

        return (left: leftSpan, right: rightSpan)
    }
}

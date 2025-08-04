/// Styled text representation with multiple spans
///
/// This module provides the StyledText structure that represents text
/// with multiple styling spans and supports various text operations.

import RuneUnicode

/// A collection of styled text spans representing formatted text
///
/// StyledText represents text that may have multiple different styling
/// attributes applied to different portions. It consists of an ordered
/// collection of TextSpan objects.
public struct StyledText: Equatable, Hashable {
    /// The text spans that make up this styled text
    public let spans: [TextSpan]

    /// Initialize styled text with an array of spans
    ///
    /// - Parameter spans: The text spans to include
    public init(spans: [TextSpan]) {
        self.spans = spans
    }

    /// Create styled text from a single span
    ///
    /// - Parameter span: The text span to wrap
    /// - Returns: StyledText containing the single span
    public static func single(_ span: TextSpan) -> StyledText {
        StyledText(spans: [span])
    }

    /// Create plain styled text with no formatting
    ///
    /// - Parameter text: The plain text content
    /// - Returns: StyledText with default attributes
    public static func plain(_ text: String) -> StyledText {
        StyledText(spans: [TextSpan.plain(text)])
    }

    /// Extract the plain text content without any formatting
    public var plainText: String {
        spans.map(\.text).joined()
    }

    /// Check if this styled text is empty
    public var isEmpty: Bool {
        spans.isEmpty || spans.allSatisfy(\.isEmpty)
    }

    /// The total length of all text content
    public var length: Int {
        spans.reduce(0) { $0 + $1.length }
    }

    /// Check if this styled text contains only plain text (no formatting)
    public var isPlain: Bool {
        spans.allSatisfy(\.isPlain)
    }

    /// Merge adjacent spans with identical attributes
    ///
    /// This method combines consecutive spans that have the same attributes
    /// into single spans, reducing the total number of spans while preserving
    /// all text content and formatting.
    ///
    /// - Returns: A new StyledText with merged spans
    public func mergingAdjacentSpans() -> StyledText {
        guard !spans.isEmpty else { return self }

        var mergedSpans: [TextSpan] = []
        var currentSpan = spans[0]

        for i in 1 ..< spans.count {
            let nextSpan = spans[i]

            // If attributes match, merge the text
            if currentSpan.attributes == nextSpan.attributes {
                currentSpan = TextSpan(
                    text: currentSpan.text + nextSpan.text,
                    attributes: currentSpan.attributes,
                    )
            } else {
                // Attributes don't match, save current span and start new one
                mergedSpans.append(currentSpan)
                currentSpan = nextSpan
            }
        }

        // Don't forget the last span
        mergedSpans.append(currentSpan)

        return StyledText(spans: mergedSpans)
    }

    /// Split styled text at the specified column position
    ///
    /// This method splits the styled text into two parts at the given column
    /// position, preserving all formatting and handling spans that cross the
    /// split boundary.
    ///
    /// - Parameter column: The column position at which to split (0-based)
    /// - Returns: A tuple containing the left and right parts
    public func split(at column: Int) -> (left: StyledText, right: StyledText) {
        guard column > 0 else {
            return (left: StyledText(spans: []), right: self)
        }

        guard column < length else {
            return (left: self, right: StyledText(spans: []))
        }

        var leftSpans: [TextSpan] = []
        var rightSpans: [TextSpan] = []
        var currentColumn = 0

        for span in spans {
            let spanEnd = currentColumn + span.length

            if spanEnd <= column {
                // Entire span fits in the left part
                leftSpans.append(span)
            } else if currentColumn >= column {
                // Entire span goes to the right
                rightSpans.append(span)
            } else {
                // Span crosses the split boundary
                let splitIndex = column - currentColumn
                let (leftPart, rightPart) = span.split(at: splitIndex)

                if !leftPart.text.isEmpty {
                    leftSpans.append(leftPart)
                }
                if !rightPart.text.isEmpty {
                    rightSpans.append(rightPart)
                }
            }

            currentColumn = spanEnd
        }

        return (
            left: StyledText(spans: leftSpans),
            right: StyledText(spans: rightSpans),
            )
    }

    /// Split styled text at the specified display width position
    ///
    /// This method splits the styled text into two parts at the given display width
    /// position, preserving all formatting and handling grapheme cluster boundaries.
    /// Unlike character-based splitting, this considers the actual terminal display width.
    ///
    /// - Parameters:
    ///   - displayWidth: The display width position at which to split (0-based)
    ///   - lastColumnGuard: If true, prevents 2-width characters from being placed at the last column
    /// - Returns: A tuple containing the left and right parts
    public func splitByDisplayWidth(
        at displayWidth: Int,
        lastColumnGuard: Bool = false,
        ) -> (left: StyledText, right: StyledText) {
        guard displayWidth > 0 else {
            return (left: StyledText(spans: []), right: self)
        }

        var leftSpans: [TextSpan] = []
        var rightSpans: [TextSpan] = []
        var currentDisplayWidth = 0

        for span in spans {
            let spanDisplayWidth = Width.displayWidth(of: span.text)
            let spanEnd = currentDisplayWidth + spanDisplayWidth

            if spanEnd <= displayWidth {
                // Entire span fits in the left part
                leftSpans.append(span)
            } else if currentDisplayWidth >= displayWidth {
                // Entire span goes to the right
                rightSpans.append(span)
            } else {
                // Span crosses the split boundary - need to split within the span
                let (leftPart, rightPart) = span.splitByDisplayWidth(
                    at: displayWidth - currentDisplayWidth,
                    lastColumnGuard: lastColumnGuard,
                    )

                if !leftPart.text.isEmpty {
                    leftSpans.append(leftPart)
                }
                if !rightPart.text.isEmpty {
                    rightSpans.append(rightPart)
                }
            }

            currentDisplayWidth = spanEnd
        }

        return (
            left: StyledText(spans: leftSpans),
            right: StyledText(spans: rightSpans),
            )
    }

    /// Wrap styled text by display width into multiple lines
    ///
    /// This method wraps the styled text into multiple lines based on display width,
    /// preserving all formatting and ensuring proper SGR sequence handling across lines.
    ///
    /// - Parameter width: The maximum display width per line
    /// - Returns: Array of StyledText representing each wrapped line
    public func wrapByDisplayWidth(width: Int) -> [StyledText] {
        guard width > 0 else { return [] }
        guard !spans.isEmpty else { return [] }

        var lines: [StyledText] = []
        var remaining = self

        while !remaining.spans.isEmpty {
            let (line, rest) = remaining.splitByDisplayWidth(at: width)

            if !line.spans.isEmpty {
                lines.append(line)
            }

            remaining = rest

            // Prevent infinite loop if we can't make progress
            if remaining.spans.isEmpty || remaining == self {
                break
            }
        }

        return lines
    }

    /// Slice styled text by display column range
    ///
    /// This method extracts a substring based on display column positions,
    /// preserving formatting and handling grapheme cluster boundaries.
    ///
    /// - Parameters:
    ///   - from: Starting display column (inclusive)
    ///   - to: Ending display column (exclusive)
    /// - Returns: StyledText containing the sliced content
    public func sliceByDisplayColumns(from: Int, to: Int) -> StyledText {
        guard from >= 0, to > from else {
            return StyledText(spans: [])
        }

        // First split at the 'from' position to get the right part
        let (_, rightPart) = splitByDisplayWidth(at: from)

        // Then split the right part at (to - from) to get the middle slice
        let sliceWidth = to - from
        let (slicePart, _) = rightPart.splitByDisplayWidth(at: sliceWidth)

        return slicePart
    }
}

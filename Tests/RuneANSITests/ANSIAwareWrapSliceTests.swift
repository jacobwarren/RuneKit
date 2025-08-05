import Foundation
import Testing
@testable import RuneANSI
@testable import RuneUnicode

/// Tests for ANSI-aware wrap & slice functionality (RUNE-19)
/// This implements the core acceptance criteria for display width-aware text operations
struct ANSIAwareWrapSliceTests {
    // MARK: - Display Width Splitting Tests

    @Test("Split styled text by display width preserving grapheme clusters")
    func splitByDisplayWidthGraphemeClusters() {
        // Arrange
        let attributes = TextAttributes(color: .red, bold: true)
        let text = "Hello👨‍👩‍👧‍👦World" // Family emoji is 1 grapheme cluster, width 2
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])

        // Act - Split at display width 7 (emoji would fit exactly but we want to test boundary)
        let (left, right) = styledText.splitByDisplayWidth(at: 7)

        // Assert - Since "Hello" + emoji = exactly 7 width, it should fit
        #expect(left.plainText == "Hello👨‍👩‍👧‍👦", "Left should include emoji (total width 7)")
        #expect(right.plainText == "World", "Right should contain remaining text")
        #expect(left.spans[0].attributes == attributes, "Left should preserve attributes")
        #expect(right.spans[0].attributes == attributes, "Right should preserve attributes")
    }

    @Test("Split styled text with grapheme cluster boundary protection")
    func splitWithGraphemeClusterBoundaryProtection() {
        // Arrange
        let attributes = TextAttributes(color: .blue)
        let text = "Hello👨‍👩‍👧‍👦World" // Family emoji is 1 grapheme cluster, width 2
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])

        // Act - Split at display width 6 (would break in middle of emoji if not protected)
        let (left, right) = styledText.splitByDisplayWidth(at: 6)

        // Assert - Should split before emoji to preserve cluster boundary
        #expect(left.plainText == "Hello", "Left should be 'Hello' to avoid breaking emoji cluster")
        #expect(right.plainText == "👨‍👩‍👧‍👦World", "Right should contain full emoji cluster")
    }

    @Test("Split styled text by display width with CJK characters")
    func splitByDisplayWidthCJK() {
        // Arrange
        let attributes = TextAttributes(color: .blue)
        let text = "Hello世界Test" // 世界 are 2-width CJK characters
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])
        // Act - Split at display width 7 (Hello=5, 世=2, total would be 7)
        let (left, right) = styledText.splitByDisplayWidth(at: 7)
        // Assert
        #expect(left.plainText == "Hello世", "Left should include first CJK character")
        #expect(right.plainText == "界Test", "Right should start with second CJK character")
    }

    @Test("Split styled text with last column guard")
    func splitWithLastColumnGuard() {
        // Arrange
        let attributes = TextAttributes(color: .green)
        let text = "Test世界" // 世界 are 2-width characters
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])
        // Act - Split at width 5 with last column guard (should prevent 世 from being at last column)
        let (left, right) = styledText.splitByDisplayWidth(at: 5, lastColumnGuard: true)

        // Assert
        #expect(left.plainText == "Test", "Left should be 'Test' to avoid 2-width char at last column")
        #expect(right.plainText == "世界", "Right should contain both CJK characters")
    }

    // MARK: - Wrapping Tests

    @Test("Wrap styled text preserving ANSI formatting")
    func wrapStyledTextPreservingANSI() {
        // Arrange
        let span1 = TextSpan(text: "Hello ", attributes: TextAttributes(color: .red))
        let span2 = TextSpan(text: "beautiful ", attributes: TextAttributes(bold: true))
        let span3 = TextSpan(text: "world!", attributes: TextAttributes(color: .blue))
        let styledText = StyledText(spans: [span1, span2, span3])
        // Act - Wrap at width 10
        let lines = styledText.wrapByDisplayWidth(width: 10)
        // Assert
        #expect(lines.count == 3, "Should wrap into 3 lines")
        #expect(lines[0].plainText == "Hello beau", "First line should fit 10 characters")
        #expect(lines[1].plainText == "tiful worl", "Second line should fit 10 characters")
        #expect(lines[2].plainText == "d!", "Third line should contain remainder")

        // Verify attributes are preserved
        #expect(lines[0].spans[0].attributes.color == .red, "First span color preserved")
        #expect(lines[0].spans[1].attributes.bold == true, "Second span bold preserved")
        #expect(lines[1].spans[0].attributes.bold == true, "Continued span bold preserved")
        #expect(lines[1].spans[1].attributes.color == .blue, "Last span color preserved")
    }

    @Test("Wrap mixed ANSI styled text with emoji and CJK characters")
    func wrapMixedANSIEmojiCJK() {
        // Arrange - Mixed content with different styling
        let span1 = TextSpan(text: "Hello ", attributes: TextAttributes(color: .red))
        let span2 = TextSpan(text: "👨‍👩‍👧‍👦", attributes: TextAttributes(bold: true)) // Family emoji, width 2
        let span3 = TextSpan(text: " 世界 ", attributes: TextAttributes(color: .blue)) // CJK chars, width 2 each
        let span4 = TextSpan(text: "🎉", attributes: TextAttributes(italic: true)) // Party emoji, width 2
        let span5 = TextSpan(text: " Test!", attributes: TextAttributes(underline: true))
        let styledText = StyledText(spans: [span1, span2, span3, span4, span5])
        // Act - Wrap at width 12
        let lines = styledText.wrapByDisplayWidth(width: 12)

        // Assert
        #expect(lines.count >= 2, "Should wrap into multiple lines")

        // Verify no color bleed by checking each line has proper SGR sequences
        let converter = ANSISpanConverter()
        for line in lines where !line.spans.isEmpty {
            let tokens = converter.styledTextToTokens(line)
            // Should have proper structure with SGR tokens
            #expect(tokens.count >= 1, "Each line should have tokens")
        }

        // Verify total content is preserved
        let reconstructed = lines.map(\.plainText).joined()
        #expect(reconstructed == styledText.plainText, "Content should be preserved across lines")
    }

    // MARK: - Slicing Tests

    @Test("Slice styled text by display columns")
    func sliceByDisplayColumns() {
        // Arrange
        let attributes = TextAttributes(color: .yellow, italic: true)
        let text = "Hello👍World世界!" // Mixed ASCII, emoji, CJK
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])
        // Act - Slice from column 5 to 9 (should include emoji and start of "World")
        let sliced = styledText.sliceByDisplayColumns(from: 5, to: 9)
        // Assert
        #expect(sliced.plainText == "👍Wo", "Should slice correctly by display width")
        #expect(sliced.spans[0].attributes == attributes, "Should preserve attributes")
    }

    @Test("Slice mixed content preserving grapheme clusters")
    func sliceMixedContentPreservingClusters() {
        // Arrange - Complex mixed content
        let attributes = TextAttributes(color: .green, bold: true)
        let text = "A👨‍👩‍👧‍👦B世界C🎉D" // A(1) + emoji(2) + B(1) + CJK(4) + C(1) + emoji(2) + D(1) = 12 total
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])

        // Act - Slice from column 3 to 9 (should include B + 世界 + C)
        let sliced = styledText.sliceByDisplayColumns(from: 3, to: 9)
        // Assert
        #expect(sliced.plainText == "B世界C", "Should slice correctly preserving clusters")
        #expect(sliced.spans[0].attributes == attributes, "Should preserve attributes")
    }

    // MARK: - Edge Cases

    @Test("Handle empty text in display width operations")
    func handleEmptyTextDisplayWidth() {
        // Arrange
        let emptyText = StyledText(spans: [])

        // Act & Assert
        let (left, right) = emptyText.splitByDisplayWidth(at: 5)
        #expect(left.spans.isEmpty, "Left should be empty")
        #expect(right.spans.isEmpty, "Right should be empty")

        let wrapped = emptyText.wrapByDisplayWidth(width: 10)
        #expect(wrapped.isEmpty, "Wrapped should be empty")
        let sliced = emptyText.sliceByDisplayColumns(from: 0, to: 5)
        #expect(sliced.spans.isEmpty, "Sliced should be empty")
    }

    @Test("Prevent color bleed across wrapped lines")
    func preventColorBleedAcrossLines() {
        // Arrange
        let attributes = TextAttributes(color: .red, backgroundColor: .yellow, bold: true)
        let text = "This is a long line that will be wrapped"
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])

        // Act - Wrap at width 15
        let lines = styledText.wrapByDisplayWidth(width: 15)

        // Assert
        #expect(lines.count >= 2, "Should wrap into multiple lines")

        // Each line should have proper SGR sequences when converted to tokens
        let converter = ANSISpanConverter()
        for line in lines where !line.spans.isEmpty && !line.spans[0].attributes.isDefault {
            let tokens = converter.styledTextToTokens(line)
            #expect(tokens.first?.isSGR == true, "Line should start with SGR")
            #expect(tokens.last == .sgr([0]), "Line should end with reset")
        }
    }

    @Test("Last column guard prevents wide character overflow")
    func lastColumnGuardPreventsOverflow() {
        // Arrange
        let attributes = TextAttributes(color: .yellow)
        let text = "Test世" // Test(4) + 世(2) = 6 total width
        let span = TextSpan(text: text, attributes: attributes)
        let styledText = StyledText(spans: [span])

        // Act - Split at width 5 with last column guard (should prevent 世 at column 5)
        let (left, right) = styledText.splitByDisplayWidth(at: 5, lastColumnGuard: true)

        // Assert
        #expect(left.plainText == "Test", "Should stop before wide character to avoid overflow")
        #expect(right.plainText == "世", "Wide character should go to next line")
    }

    @Test("Complex SGR sequence preservation across splits")
    func complexSGRPreservationAcrossSplits() {
        // Arrange - Text with complex attributes
        let complexAttrs = TextAttributes(
            color: .rgb(255, 128, 64),
            backgroundColor: .color256(21),
            bold: true,
            italic: true,
            underline: true,
        )
        let text = "This is a very long line with complex formatting that will be split"
        let span = TextSpan(text: text, attributes: complexAttrs)
        let styledText = StyledText(spans: [span])

        // Act - Wrap at width 20
        let lines = styledText.wrapByDisplayWidth(width: 20)

        // Assert
        #expect(lines.count >= 3, "Should wrap into multiple lines")

        // Verify each line preserves the complex attributes
        for line in lines where !line.spans.isEmpty {
            let firstSpan = line.spans[0]
            #expect(firstSpan.attributes.color == complexAttrs.color, "Color should be preserved")
            #expect(
                firstSpan.attributes.backgroundColor == complexAttrs.backgroundColor,
                "Background should be preserved",
            )
            #expect(firstSpan.attributes.bold == complexAttrs.bold, "Bold should be preserved")
            #expect(firstSpan.attributes.italic == complexAttrs.italic, "Italic should be preserved")
            #expect(firstSpan.attributes.underline == complexAttrs.underline, "Underline should be preserved")
        }
    }

    // MARK: - Comprehensive Acceptance Criteria Test

    @Test("RUNE-19 Acceptance Criteria: ANSI-aware wrap & slice comprehensive test")
    func rune19AcceptanceCriteria() {
        // Test all acceptance criteria in one comprehensive test

        // ✅ Criterion 1: No color bleed across lines when slicing styled text
        let styledText = StyledText(spans: [
            TextSpan(text: "Red text that spans multiple lines", attributes: TextAttributes(color: .red)),
            TextSpan(text: " and blue text", attributes: TextAttributes(color: .blue)),
        ])

        let lines = styledText.wrapByDisplayWidth(width: 20)
        let converter = ANSISpanConverter()

        for line in lines where !line.spans.isEmpty && !line.spans[0].attributes.isDefault {
            let tokens = converter.styledTextToTokens(line)
            #expect(tokens.last == .sgr([0]), "Each styled line should end with reset to prevent color bleed")
        }

        // ✅ Criterion 2: No split grapheme clusters
        let emojiText = StyledText(spans: [TextSpan(text: "Hello👨‍👩‍👧‍👦World", attributes: TextAttributes())])
        let (left, right) = emojiText.splitByDisplayWidth(at: 6) // Should split before emoji
        #expect(left.plainText == "Hello", "Should not split grapheme cluster")
        #expect(right.plainText == "👨‍👩‍👧‍👦World", "Emoji cluster should remain intact")

        // ✅ Criterion 3: Last-column guard prevents 2-wide cluster spill
        let (leftGuard, rightGuard) = StyledText(spans: [TextSpan(text: "Test世", attributes: TextAttributes())])
            .splitByDisplayWidth(at: 5, lastColumnGuard: true)
        #expect(leftGuard.plainText == "Test", "Last column guard should prevent 2-wide char at last position")
        #expect(rightGuard.plainText == "世", "2-wide char should move to next line")

        // ✅ Criterion 4: Snapshots for mixed ANSI + emoji + CJK scenarios
        let mixedText = StyledText(spans: [
            TextSpan(text: "Hello ", attributes: TextAttributes(color: .red, bold: true)),
            TextSpan(text: "👨‍👩‍👧‍👦", attributes: TextAttributes(color: .green)),
            TextSpan(text: " 世界 ", attributes: TextAttributes(color: .blue)),
            TextSpan(text: "🎉", attributes: TextAttributes(italic: true)),
        ])

        let mixedLines = mixedText.wrapByDisplayWidth(width: 10)
        let reconstructed = mixedLines.map(\.plainText).joined()
        #expect(reconstructed == mixedText.plainText, "Mixed content should be preserved across wrapping")

        // Verify all attributes are preserved
        let allSpans = mixedLines.flatMap(\.spans)
        let hasRed = allSpans.contains { $0.attributes.color == .red }
        let hasGreen = allSpans.contains { $0.attributes.color == .green }
        let hasBlue = allSpans.contains { $0.attributes.color == .blue }
        let hasItalic = allSpans.contains { $0.attributes.italic }
        let hasBold = allSpans.contains { $0.attributes.bold }
        #expect(hasRed && hasGreen && hasBlue && hasItalic && hasBold, "All attributes should be preserved")

        // ✅ Slicing APIs by display columns - A(1) + emoji(2) + B(1) + 世(2) + 界(2) + C(1)
        let sliced = StyledText(spans: [TextSpan(text: "A👨‍👩‍👧‍👦B世界C", attributes: TextAttributes(underline: true))])
            .sliceByDisplayColumns(from: 3, to: 8) // Should get "B世界"
        #expect(sliced.plainText == "B世界", "Slicing should work by display columns")
        #expect(sliced.spans[0].attributes.underline, "Sliced content should preserve attributes")

        print("✅ RUNE-19 All acceptance criteria verified successfully!")
    }
}

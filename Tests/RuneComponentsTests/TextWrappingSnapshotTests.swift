import Foundation
import Testing
import TestSupport
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneUnicode

struct TextWrappingSnapshotTests {
    @Test("Snapshot: wrap mixed styles + emoji/ZWJ/CJK")
    func snapshotWrapMixed() {
        // Arrange
        let content = "Hello 👨‍👩‍👧‍👦 世界 🎉 Test!"
        let text = Text(content, color: .red, bold: true)
        // Act: use wrapping helper directly (independent of render semantics)
        let lines = text.wrappedLines(width: 10)
        // Assert
        Snapshot.assertLinesSnapshot(lines, named: "wrap_mixed_styles_emoji_cjk")
    }
}

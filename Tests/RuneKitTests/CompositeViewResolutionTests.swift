import Foundation
import Testing
@testable import RuneComponents
@testable import RuneKit

@Suite("Composite View resolution renders child components (no placeholders)")
struct CompositeViewResolutionTests {
    struct AltView: View { var body: some View { Box(border: .single, child: Text("Alt Screen Demo", color: .white, bold: true)) } }

    @Test("Composite view body is converted to Box/Text and renders border glyphs")
    func compositeBodyResolvesToLeafComponents() async {
        // Arrange
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false)
        let handle = await render(AltView(), options: options)

        // Act: trigger one rerender to exercise the pipeline
        await handle.rerender(AltView())
        // Small delay to let async write complete in CI
        try? await Task.sleep(for: .milliseconds(10))

        // We can't read the terminal here; instead, re-run conversion locally and assert lines
        let frame = await RuneKit.convertForTesting(AltView())
        let joined = frame.lines.joined(separator: "\n")

        // Assert: contains box-drawing glyphs and our text
        #expect(joined.contains("┌") || joined.contains("╭"), "Missing top-left border glyph in rendered lines: \n\(joined)")
        #expect(joined.contains("┐") || joined.contains("╮"), "Missing top-right border glyph")
        #expect(joined.contains("Alt Screen Demo"), "Missing inner text")

        await handle.unmount()
    }
}


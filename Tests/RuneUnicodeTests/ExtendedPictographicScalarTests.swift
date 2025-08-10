import Testing
@testable import RuneUnicode

/// Verifies that isEmojiScalar matches Extended_Pictographic generated table at key boundaries
struct ExtendedPictographicScalarTests {
    @Test("Basic EP boundary checks")
    func boundaryChecks() {
        // Known EP examples from emoji-data.txt
        let scalars: [(UInt32, Bool)] = [
            // EP includes pictographic scalars; ASCII '#' is not EP (keycap base)
            (0x0023, false), // '#'
            (0x1F3F3, true), // white flag base
            (0x1F3F4, true), // black flag base
            (0x1F1E6, false), // Regional indicator A (not EP)
            (0x1F600, true), // 😀 grinning face
            (0x2764, true),  // ❤ heart
            (0x200D, false), // ZWJ is not EP
            (0x0301, false), // combining acute
            (0x0041, false), // 'A'
        ]
        for (u, expected) in scalars {
            guard let s = Unicode.Scalar(u) else { continue }
            #expect(UnicodeCategories.isEmojiScalar(s) == expected)
        }
    }
}


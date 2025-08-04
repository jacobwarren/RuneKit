import Foundation
import Testing
@testable import RuneUnicode

/// Tests for Unicode normalization and metadata functionality
struct UnicodeCategoriesNormalizationTests {
    // MARK: - Normalization Tests

    @Test("Unicode normalization NFC")
    func unicodeNormalizationNFC() {
        // Arrange - Decomposed form: e + combining acute accent
        let decomposed = "e\u{0301}" // e + ́
        let expectedComposed = "é" // precomposed é

        // Act
        let normalized = UnicodeNormalization.normalize(decomposed, form: .nfc)

        // Assert
        #expect(
            normalized == expectedComposed,
            "NFC normalization should compose decomposed characters",
            )
    }

    @Test("Unicode normalization NFD")
    func unicodeNormalizationNFD() {
        // Arrange - Precomposed form
        let composed = "é" // precomposed é
        let expectedDecomposed = "e\u{0301}" // e + ́

        // Act
        let normalized = UnicodeNormalization.normalize(composed, form: .nfd)

        // Assert
        #expect(
            normalized == expectedDecomposed,
            "NFD normalization should decompose precomposed characters",
            )
    }

    @Test("Unicode normalization NFKC")
    func unicodeNormalizationNFKC() {
        // Arrange - Compatibility characters
        let compatibility = "ﬁ" // U+FB01 LATIN SMALL LIGATURE FI
        let expectedCanonical = "fi" // f + i

        // Act
        let normalized = UnicodeNormalization.normalize(compatibility, form: .nfkc)

        // Assert
        #expect(
            normalized == expectedCanonical,
            "NFKC normalization should decompose compatibility characters",
            )
    }

    @Test("Unicode normalization NFKD")
    func unicodeNormalizationNFKD() {
        // Arrange - Compatibility characters
        let input = "ﬁ" // U+FB01 LATIN SMALL LIGATURE FI

        // Act
        let normalized = UnicodeNormalization.normalize(input, form: .nfkd)

        // Assert
        // Should decompose the ligature into separate characters
        #expect(
            normalized.contains("f") && normalized.contains("i"),
            "NFKD normalization should decompose compatibility characters",
            )
        #expect(
            normalized == "fi",
            "NFKD should decompose ligature ﬁ to 'fi'",
            )
    }

    // MARK: - Version and Metadata Tests

    @Test("Unicode version information")
    func unicodeVersionInformation() {
        // Act
        let version = UnicodeCategories.unicodeVersion()

        // Assert
        #expect(!version.isEmpty, "Unicode version should not be empty")
        #expect(version != "Unknown", "Unicode version should be available")

        // Version should be in MAJOR.MINOR.PATCH format
        let components = version.split(separator: ".")
        #expect(components.count >= 2, "Version should have at least major.minor components")

        // Should be a reasonable Unicode version (>= 10.0)
        if let major = Int(components[0]) {
            #expect(major >= 10, "Unicode version should be 10.0 or higher")
        }
    }
}

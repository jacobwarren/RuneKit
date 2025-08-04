import Foundation
import Testing
@testable import RuneUnicode

/// Tests for basic Unicode width calculation functionality
struct WidthBasicTests {
    // MARK: - Basic ASCII Tests

    @Test("Empty string has zero width")
    func emptyStringWidth() {
        // Arrange
        let input = ""

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 0, "Empty string should have zero width")
    }

    @Test("ASCII characters have width 1")
    func aSCIIWidth() {
        // Arrange
        let input = "Hello"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 5, "ASCII string 'Hello' should have width 5")
    }

    @Test("ASCII string with spaces")
    func aSCIIWithSpaces() {
        // Arrange
        let input = "Hello World"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 11, "ASCII string 'Hello World' should have width 11")
    }

    // MARK: - Grapheme Cluster Width Tests (RUNE-18)

    @Test("Grapheme cluster API for simple ASCII")
    func graphemeClusterASCII() {
        // Arrange
        let cluster = "A".first! // Extended grapheme cluster

        // Act
        let width = Width.displayWidth(of: cluster)

        // Assert
        #expect(width == 1, "ASCII character cluster should have width 1")
    }

    @Test("Grapheme cluster API for combining character")
    func graphemeClusterCombining() {
        // Arrange
        let cluster = "é".first! // e + combining acute accent

        // Act
        let width = Width.displayWidth(of: cluster)

        // Assert
        #expect(width == 1, "Combining character cluster should have width 1")
    }

    @Test("Grapheme cluster API for East Asian character")
    func graphemeClusterEastAsian() {
        // Arrange
        let cluster = "世".first! // East Asian ideograph

        // Act
        let width = Width.displayWidth(of: cluster)

        // Assert
        #expect(width == 2, "East Asian character cluster should have width 2")
    }

    // MARK: - Scalar-level Tests

    @Test("ASCII scalar width")
    func aSCIIScalarWidth() {
        // Arrange
        let scalar = Unicode.Scalar(65)! // 'A'

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 1, "ASCII character should have width 1")
    }

    @Test("Control character scalar width")
    func controlCharacterScalarWidth() {
        // Arrange
        let scalar = Unicode.Scalar(9)! // Tab character

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 1, "Tab character should have width 1")
    }

    @Test("East Asian scalar width")
    func eastAsianScalarWidth() {
        // Arrange
        let scalar = Unicode.Scalar(0x4E16)! // 世 (CJK ideograph)

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 2, "East Asian character should have width 2")
    }

    // MARK: - Edge Cases

    @Test("Null character width")
    func nullCharacterWidth() {
        // Arrange
        let scalar = Unicode.Scalar(0)! // Null character

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 0, "Null character should have width 0")
    }

    @Test("Space character width")
    func spaceCharacterWidth() {
        // Arrange
        let scalar = Unicode.Scalar(32)! // Space character

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 1, "Space character should have width 1")
    }

    @Test("Delete character width")
    func deleteCharacterWidth() {
        // Arrange
        let scalar = Unicode.Scalar(127)! // DEL character

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 0, "Delete character should have width 0")
    }
}

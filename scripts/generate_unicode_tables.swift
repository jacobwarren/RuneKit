#!/usr/bin/env swift

/// Unicode Data Table Generator for RuneKit
///
/// This script generates optimized lookup tables for Unicode properties used in RuneKit,
/// specifically for East Asian Width and emoji detection. The tables are generated from
/// the official Unicode data files and optimized for fast runtime lookup.
///
/// ## Usage
/// ```bash
/// swift Scripts/generate_unicode_tables.swift
/// ```
///
/// ## Generated Files
/// - `Sources/RuneUnicode/Generated/EastAsianWidthTables.swift`
/// - `Sources/RuneUnicode/Generated/EmojiTables.swift`
///
/// ## Data Sources
/// The script downloads and processes official Unicode data files:
/// - EastAsianWidth.txt (UAX #11)
/// - emoji-data.txt (Unicode Emoji)
/// - UnicodeData.txt (General Categories)
///
/// ## Update Process
/// 1. Run this script to generate new tables
/// 2. Review the generated files for correctness
/// 3. Run tests to ensure compatibility
/// 4. Commit the updated tables

import Foundation

// MARK: - Configuration

enum Config {
    static let unicodeVersion = "15.1.0"
    static let baseURL = "https://www.unicode.org/Public/\(unicodeVersion)/ucd/"
    static let emojiDir = "emoji/"
    static let outputDir = "Sources/RuneUnicode/Generated"

    static let dataFiles = [
        "EastAsianWidth.txt",
        "emoji-data.txt",
        "UnicodeData.txt",
    ]
}

// MARK: - Data Structures

struct UnicodeRange {
    let start: UInt32
    let end: UInt32
    let property: String

    init(start: UInt32, end: UInt32, property: String) {
        self.start = start
        self.end = end
        self.property = property
    }

    init(codePoint: UInt32, property: String) {
        start = codePoint
        end = codePoint
        self.property = property
    }
}

// MARK: - Main Generator

class UnicodeTableGenerator {
    func generate() throws {
        print("🚀 Generating Unicode tables for RuneKit...")
        print("📊 Unicode version: \(Config.unicodeVersion)")

        // Create output directory
        try createOutputDirectory()

        // Download and process data files
        let eastAsianWidthData = try downloadAndParseEastAsianWidth()
        let emojiData = try downloadAndParseEmojiData()

        // Generate Swift files
        try generateEastAsianWidthTables(eastAsianWidthData)
        try generateEmojiTables(emojiData)

        print("✅ Unicode tables generated successfully!")
        print("📁 Output directory: \(Config.outputDir)")
        print("🔄 Next steps:")
        print("   1. Review generated files")
        print("   2. Run tests: swift test --filter RuneUnicodeTests")
        print("   3. Commit changes if tests pass")
    }

    private func createOutputDirectory() throws {
        let fileManager = FileManager.default
        let outputURL = URL(fileURLWithPath: Config.outputDir)

        if !fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)
            print("📁 Created output directory: \(Config.outputDir)")
        }
    }

    // MARK: - East Asian Width Processing

    private func downloadAndParseEastAsianWidth() throws -> [UnicodeRange] {
        print("📥 Downloading EastAsianWidth.txt...")

        let url = URL(string: Config.baseURL + "EastAsianWidth.txt")!
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8)!

        print("📝 Parsing East Asian Width data...")
        return parseEastAsianWidthData(content)
    }

    private func parseEastAsianWidthData(_ content: String) -> [UnicodeRange] {
        var ranges: [UnicodeRange] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse line format: "0000..001F;N  # [32] <control-0000>..<control-001F>"
            let parts = trimmed.components(separatedBy: ";")
            guard parts.count >= 2 else { continue }

            let rangePart = parts[0].trimmingCharacters(in: .whitespaces)
            let propertyPart = parts[1].components(separatedBy: "#")[0].trimmingCharacters(in: .whitespaces)

            if rangePart.contains("..") {
                // Range format: "0000..001F"
                let rangeParts = rangePart.components(separatedBy: "..")
                guard rangeParts.count == 2,
                      let start = UInt32(rangeParts[0], radix: 16),
                      let end = UInt32(rangeParts[1], radix: 16) else { continue }

                ranges.append(UnicodeRange(start: start, end: end, property: propertyPart))
            } else {
                // Single code point: "0000"
                guard let codePoint = UInt32(rangePart, radix: 16) else { continue }
                ranges.append(UnicodeRange(codePoint: codePoint, property: propertyPart))
            }
        }

        print("📊 Parsed \(ranges.count) East Asian Width ranges")
        return ranges
    }

    // MARK: - Emoji Processing

    private func downloadAndParseEmojiData() throws -> [UnicodeRange] {
        print("📥 Downloading emoji-data.txt...")

        // emoji-data.txt is in ucd/emoji/ per Unicode directory structure
        let url = URL(string: Config.baseURL + Config.emojiDir + "emoji-data.txt")!
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8)!

        print("📝 Parsing emoji data...")
        return parseEmojiData(content)
    }

    private func parseEmojiData(_ content: String) -> [UnicodeRange] {
        var ranges: [UnicodeRange] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse line format: "0023..0023    ; Emoji                # E0.0   [1] (#️)"
            let parts = trimmed.components(separatedBy: ";")
            guard parts.count >= 2 else { continue }

            let rangePart = parts[0].trimmingCharacters(in: .whitespaces)
            let propertyPart = parts[1].components(separatedBy: "#")[0].trimmingCharacters(in: .whitespaces)

            // Only include Extended_Pictographic property for emoji width
            guard propertyPart == "Extended_Pictographic" else { continue }

            if rangePart.contains("..") {
                // Range format: "0023..0023"
                let rangeParts = rangePart.components(separatedBy: "..")
                guard rangeParts.count == 2,
                      let start = UInt32(rangeParts[0], radix: 16),
                      let end = UInt32(rangeParts[1], radix: 16) else { continue }

                ranges.append(UnicodeRange(start: start, end: end, property: propertyPart))
            } else {
                // Single code point: "0023"
                guard let codePoint = UInt32(rangePart, radix: 16) else { continue }
                ranges.append(UnicodeRange(codePoint: codePoint, property: propertyPart))
            }
        }

        print("📊 Parsed \(ranges.count) emoji ranges")
        return ranges
    }

    // MARK: - Code Generation

    private func generateEastAsianWidthTables(_ ranges: [UnicodeRange]) throws {
        let outputPath = "\(Config.outputDir)/EastAsianWidthTables.swift"

        var code = """
        /// Generated East Asian Width lookup tables
        /// 
        /// This file is automatically generated by Scripts/generate_unicode_tables.swift
        /// Do not edit manually. To update, run the generation script.
        ///
        /// Unicode version: \(Config.unicodeVersion)
        /// Generated: \(Date())

        import Foundation

        extension EastAsianWidth {

            /// Optimized lookup tables for East Asian Width property
            internal enum Tables {

        """

        // Generate tables for each property
        let properties = Set(ranges.map(\.property))

        for property in properties.sorted() {
            let propertyRanges = ranges.filter { $0.property == property }
            code += generateRangeTable(property: property, ranges: propertyRanges)
        }

        code += """
            }
        }
        """

        try code.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("📄 Generated: \(outputPath)")
    }

    private func generateEmojiTables(_ ranges: [UnicodeRange]) throws {
        let outputPath = "\(Config.outputDir)/EmojiTables.swift"

        let code = """
        /// Generated Emoji lookup tables
        /// 
        /// This file is automatically generated by Scripts/generate_unicode_tables.swift
        /// Do not edit manually. To update, run the generation script.
        ///
        /// Unicode version: \(Config.unicodeVersion)
        /// Generated: \(Date())

        import Foundation

        extension EmojiWidth {

            /// Optimized lookup tables for emoji detection
            internal enum Tables {
        \(generateRangeTable(property: "Extended_Pictographic", ranges: ranges))
            }
        }
        """

        try code.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("📄 Generated: \(outputPath)")
    }

    private func generateRangeTable(property: String, ranges: [UnicodeRange]) -> String {
        let tableName = property.lowercased().replacingOccurrences(of: "_", with: "")

        var code = """

                /// \(property) ranges
                static let \(tableName)Ranges: [(UInt32, UInt32)] = [
        """

        for range in ranges.sorted(by: { $0.start < $1.start }) {
            code += """
                        (0x\(String(range.start, radix: 16, uppercase: true)), 0x\(String(
                            range.end,
                            radix: 16,
                            uppercase: true,
                        ))),
            """
        }

        code += """
                ]
        """

        return code
    }
}

// MARK: - Script Entry Point

do {
    let generator = UnicodeTableGenerator()
    try generator.generate()
} catch {
    print("❌ Error: \(error)")
    exit(1)
}

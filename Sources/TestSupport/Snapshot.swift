import Foundation
import Testing

public enum Snapshot {
    public static let regenerate = ProcessInfo.processInfo.environment["RUNEKIT_REGENERATE_SNAPSHOTS"] == "1"

    public static func assertLinesSnapshot(
        _ lines: [String],
        named name: String,
        file _: StaticString = #file,
        line _: UInt = #line,
    ) {
        let dirURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Snapshot.swift
            .appendingPathComponent("__snapshots__", isDirectory: true)

        let fm = FileManager.default
        if !fm.fileExists(atPath: dirURL.path) {
            try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }

        let fileURL = dirURL.appendingPathComponent(name + ".txt")
        let content = lines.joined(separator: "\n") + "\n"

        if regenerate {
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            #expect(true, "Regenerated snapshot: \(fileURL.path)")
            return
        }

        guard let data = try? Data(contentsOf: fileURL), let expected = String(data: data, encoding: .utf8) else {
            #expect(false, "Missing snapshot file: \(fileURL.path). Run with RUNEKIT_REGENERATE_SNAPSHOTS=1 to create.")
            return
        }
        let actual = content
        #expect(expected == actual, "Snapshot mismatch for \(name). To update: set RUNEKIT_REGENERATE_SNAPSHOTS=1")
    }
}

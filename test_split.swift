#!/usr/bin/env swift

import Foundation

// Test how split works with newlines
let lines = ["Line 1", "Line 2", "Line 3"]
let content = lines.joined(separator: "\n")
let contentWithNewline = content + "\n"

print("Original lines: \(lines)")
print("Content: '\(content)'")
print("Content with newline: '\(contentWithNewline)'")
print("Content.split count: \(content.split(separator: "\n").count)")
print("ContentWithNewline.split count: \(contentWithNewline.split(separator: "\n").count)")

// What JavaScript does:
let jsStyle = contentWithNewline.split(separator: "\n", omittingEmptySubsequences: false).count
print("JS-style split count (with empty): \(jsStyle)")

// Manual count
let manualCount = contentWithNewline.components(separatedBy: "\n").count
print("Components separated by count: \(manualCount)")

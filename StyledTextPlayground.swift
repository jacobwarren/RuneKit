#!/usr/bin/env swift

// To run this playground:
// 1. Make sure you're in the RuneKit directory
// 2. Run: swift StyledTextPlayground.swift

import Foundation

// Since we can't import the package directly in a script,
// you would need to copy the relevant source files or use this as a template
// for a proper Swift Playground in Xcode.

print("=== RuneKit Styled Text Spans Playground ===")
print("")
print("This is a template for experimenting with styled text spans.")
print("To use the actual RuneKit functionality:")
print("")
print("1. Open Xcode and create a new Playground")
print("2. Add RuneKit as a dependency to your project")
print("3. Import RuneKit in your playground")
print("4. Copy the examples from StyledTextExample.swift")
print("")
print("Example code structure:")
print("""
import RuneKit

let tokenizer = ANSITokenizer()
let converter = ANSISpanConverter()

// Your experiments here...
let input = "\\u{001B}[1;31mRed Bold Text\\u{001B}[0m"
let tokens = tokenizer.tokenize(input)
let styledText = converter.tokensToStyledText(tokens)

print("Spans: \\(styledText.spans.count)")
for span in styledText.spans {
    print("  '\\(span.text)' - \\(span.attributes)")
}
""")

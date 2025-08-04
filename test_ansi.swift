#!/usr/bin/env swift

import Foundation

// Test ANSI escape sequences to understand cursor behavior
func testAnsiSequences() {
    print("Testing ANSI escape sequences...")
    print("Line 1")
    print("Line 2") 
    print("Line 3")
    
    // Now let's try to erase 3 lines and rewrite
    print("About to erase 3 lines...")
    sleep(2)
    
    // Erase 3 lines using Ink.js approach
    var eraseSequence = ""
    for i in 0..<3 {
        eraseSequence += "\u{001B}[2K"  // Clear entire line
        if i < 2 {
            eraseSequence += "\u{001B}[A"  // Move cursor up
        }
    }
    eraseSequence += "\u{001B}[G"  // Move cursor to column 1
    
    print(eraseSequence, terminator: "")
    
    // Now write new content
    print("New Line 1")
    print("New Line 2")
    
    print("Done!")
}

testAnsiSequences()

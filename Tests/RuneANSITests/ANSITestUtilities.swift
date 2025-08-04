import Foundation
@testable import RuneANSI

/// Shared test utilities for RuneANSI tests
enum ANSITestUtilities {
    // This enum exists to satisfy SwiftLint file naming requirements
}

extension ANSIToken {
    /// Helper property to check if a token is an SGR token
    var isSGR: Bool {
        if case .sgr = self {
            return true
        }
        return false
    }
}

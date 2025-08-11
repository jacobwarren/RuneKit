import Foundation
import yoga.core

public enum AlignSelf: Sendable {
    case auto, flexStart, flexEnd, center, stretch, baseline
    var yogaValue: YGAlign {
        switch self {
        case .auto: YGAlign.create(rawValue: 0)
        case .flexStart: YGAlign.create(rawValue: 1)
        case .flexEnd: YGAlign.create(rawValue: 3)
        case .center: YGAlign.create(rawValue: 2)
        case .stretch: YGAlign.create(rawValue: 4)
        case .baseline: YGAlign.create(rawValue: 5)
        }
    }

    // For tests
    public static func create(rawValue: Int) -> YGAlign { YGAlign.create(rawValue: rawValue) }
}

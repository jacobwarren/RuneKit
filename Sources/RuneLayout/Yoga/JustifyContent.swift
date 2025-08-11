import Foundation
import yoga.core

public enum JustifyContent: Sendable {
    case flexStart, flexEnd, center, spaceBetween, spaceAround, spaceEvenly
    var yogaValue: YGJustify {
        switch self {
        case .flexStart: YGJustify.create(rawValue: 0)
        case .flexEnd: YGJustify.create(rawValue: 2)
        case .center: YGJustify.create(rawValue: 1)
        case .spaceBetween: YGJustify.create(rawValue: 3)
        case .spaceAround: YGJustify.create(rawValue: 4)
        case .spaceEvenly: YGJustify.create(rawValue: 5)
        }
    }

    // For tests
    public static func create(rawValue: Int) -> YGJustify { YGJustify.create(rawValue: rawValue) }
}

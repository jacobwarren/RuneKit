import Foundation
import yoga.core

public enum FlexWrap {
    case noWrap, wrap, wrapReverse
    var yogaValue: YGWrap {
        switch self {
        case .noWrap: YGWrap.create(rawValue: 0)
        case .wrap: YGWrap.create(rawValue: 1)
        case .wrapReverse: YGWrap.create(rawValue: 2)
        }
    }

    // For tests
    public static func create(rawValue: Int) -> YGWrap { YGWrap.create(rawValue: rawValue) }
}

import Foundation
import yoga.core

public enum YogaFlexDirection {
    case row, column, rowReverse, columnReverse
    var yogaValue: YGFlexDirection {
        switch self {
        case .row: YGFlexDirection.create(rawValue: 2)
        case .column: YGFlexDirection.create(rawValue: 0)
        case .rowReverse: YGFlexDirection.create(rawValue: 3)
        case .columnReverse: YGFlexDirection.create(rawValue: 1)
        }
    }

    // For tests: expose raw-value factory to validate Yoga raw values
    public static func create(rawValue: Int) -> YGFlexDirection { YGFlexDirection.create(rawValue: rawValue) }
}

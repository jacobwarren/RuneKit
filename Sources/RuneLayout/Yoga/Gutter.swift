import Foundation
import yoga.core

public enum Gutter {
    case column, row, all
    var yogaValue: YGGutter {
        switch self {
        case .column: YGGutter.create(rawValue: 0)
        case .row: YGGutter.create(rawValue: 1)
        case .all: YGGutter.create(rawValue: 2)
        }
    }
}

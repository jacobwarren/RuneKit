import Foundation
import yoga.core

public enum Edge {
    case left, top, right, bottom, start, end, horizontal, vertical, all
    var yogaValue: YGEdge {
        switch self {
        case .left: YGEdge.create(rawValue: 0)
        case .top: YGEdge.create(rawValue: 1)
        case .right: YGEdge.create(rawValue: 2)
        case .bottom: YGEdge.create(rawValue: 3)
        case .start: YGEdge.create(rawValue: 4)
        case .end: YGEdge.create(rawValue: 5)
        case .horizontal: YGEdge.create(rawValue: 6)
        case .vertical: YGEdge.create(rawValue: 7)
        case .all: YGEdge.create(rawValue: 8)
        }
    }
}

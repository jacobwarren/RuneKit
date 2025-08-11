import Foundation
import yoga.core

public enum Dimension: Equatable {
    case auto, points(Float), percent(Float)
    func applyToYogaWidth(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetWidthAuto(node)
        case let .points(value): YGNodeStyleSetWidth(node, value)
        case let .percent(value): YGNodeStyleSetWidthPercent(node, value)
        }
    }

    func applyToYogaHeight(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetHeightAuto(node)
        case let .points(value): YGNodeStyleSetHeight(node, value)
        case let .percent(value): YGNodeStyleSetHeightPercent(node, value)
        }
    }

    func applyToYogaFlexBasis(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetFlexBasisAuto(node)
        case let .points(value): YGNodeStyleSetFlexBasis(node, value)
        case let .percent(value): YGNodeStyleSetFlexBasisPercent(node, value)
        }
    }

    func applyToYogaMinWidth(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetMinWidth(node, 0)
        case let .points(value): YGNodeStyleSetMinWidth(node, value)
        case let .percent(value): YGNodeStyleSetMinWidthPercent(node, value)
        }
    }

    func applyToYogaMaxWidth(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetMaxWidth(node, Float.nan)
        case let .points(value): YGNodeStyleSetMaxWidth(node, value)
        case let .percent(value): YGNodeStyleSetMaxWidthPercent(node, value)
        }
    }

    func applyToYogaMinHeight(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetMinHeight(node, 0)
        case let .points(value): YGNodeStyleSetMinHeight(node, value)
        case let .percent(value): YGNodeStyleSetMinHeightPercent(node, value)
        }
    }

    func applyToYogaMaxHeight(_ node: YGNodeRef) {
        switch self {
        case .auto: YGNodeStyleSetMaxHeight(node, Float.nan)
        case let .points(value): YGNodeStyleSetMaxHeight(node, value)
        case let .percent(value): YGNodeStyleSetMaxHeightPercent(node, value)
        }
    }
}

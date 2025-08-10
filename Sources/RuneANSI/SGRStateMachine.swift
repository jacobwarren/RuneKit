import Foundation

/// A small wrapper over SGRParameterProcessor that maintains running TextAttributes state
public struct SGRStateMachine {
    private var processor = SGRParameterProcessor()
    public private(set) var attributes: TextAttributes

    public init(initial: TextAttributes = TextAttributes()) {
        self.attributes = initial
    }

    /// Feed SGR parameters and update state
    @discardableResult
    public mutating func apply(_ params: [Int]) -> TextAttributes {
        attributes = processor.applySGRParameters(params, to: attributes)
        return attributes
    }
}


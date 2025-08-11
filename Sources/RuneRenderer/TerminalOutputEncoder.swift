import Foundation

public protocol TerminalOutputEncoder {
    func write(_ string: String)
}

public final class FileHandleOutputEncoder: TerminalOutputEncoder {
    private let handle: FileHandle
    public init(handle: FileHandle) { self.handle = handle }
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
}

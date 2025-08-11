/// Terminal color capability profile
public enum TerminalProfile: Equatable, Hashable, Sendable {
    case trueColor
    case xterm256
    case basic16
    case noColor
}

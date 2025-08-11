import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

// MARK: - Key Model

public struct KeyModifiers: OptionSet, Sendable, Equatable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let shift = KeyModifiers(rawValue: 1 << 0)
    public static let alt   = KeyModifiers(rawValue: 1 << 1)
    public static let ctrl  = KeyModifiers(rawValue: 1 << 2)
}

public enum KeyKind: Equatable, Sendable {
    case up, down, left, right
    case home, end, pageUp, pageDown
    case function(Int) // F1..F12
}

/// Key events recognized by RuneKit input system
public enum KeyEvent: Equatable, Sendable {
    // Back-compat simple arrows and control
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case ctrlC
    case ctrlD

    // Rich key representation with modifiers
    case key(kind: KeyKind, modifiers: KeyModifiers)

    // Bracketed paste
    case paste(String)
}

// MARK: - Input Manager

/// Actor that manages raw-mode input, key decoding, and optional bracketed paste
public actor InputManager {
    private let input: FileHandle
    private let controlOut: FileHandle // writes control sequences (paste on/off) bypassing capture
    private let enableRawMode: Bool
    private let enableBracketedPaste: Bool
    private let exitOnCtrlC: Bool

    // Saved terminal state for raw mode
    private var originalTermios: termios?

    // Incremental decode buffer
    private var buffer: [UInt8] = []

    // Paste decoding state
    private var isInBracketedPaste = false
    private var pasteBuffer: [UInt8] = []

    // Event handler callback
    private var handler: (@Sendable (KeyEvent) async -> Void)?

    // Background read task
    private var readTask: Task<Void, Never>?

    public init(
        input: FileHandle,
        controlOut: FileHandle,
        enableRawMode: Bool,
        enableBracketedPaste: Bool,
        exitOnCtrlC: Bool
    ) {
        self.input = input
        self.controlOut = controlOut
        self.enableRawMode = enableRawMode
        self.enableBracketedPaste = enableBracketedPaste
        self.exitOnCtrlC = exitOnCtrlC
    }

    public func setEventHandler(_ handler: @escaping @Sendable (KeyEvent) async -> Void) {
        self.handler = handler
    }

    public func start() async {
        if enableRawMode { await enableRawModeIfTTY() }
        if enableBracketedPaste { writeControl("\u{001B}[?2004h") }

        if isATTY(input.fileDescriptor) == 1 {
            readTask = Task.detached { [weak self] in
                await self?.readLoop()
            }
        }
    }

    public func stop() async {
        readTask?.cancel(); readTask = nil
        if enableBracketedPaste { writeControl("\u{001B}[?2004l") }
        if enableRawMode { await restoreTermiosIfNeeded() }
    }

    // MARK: - Testing hooks / direct processing

    /// Directly feed bytes into the decoder (used by tests or when the caller handles I/O)
    public func process(bytes: [UInt8]) async {
        buffer.append(contentsOf: bytes)
        await decodeFromBuffer()
    }

    // MARK: - Private helpers

    private func emit(_ event: KeyEvent) async { await handler?(event) }

    private func writeControl(_ s: String) {
        if let data = s.data(using: .utf8) { controlOut.write(data) }
    }

    private func isATTY(_ fd: Int32) -> Int32 { isatty(fd) }

    private func enableRawModeIfTTY() async {
        let fd = input.fileDescriptor
        guard isATTY(fd) == 1 else { return }
        var t = termios()
        if tcgetattr(fd, &t) == 0 {
            originalTermios = t
            cfmakeraw(&t)
            // Set VMIN/VTIME: non-blocking-ish read with 100ms timeout
            withUnsafeMutablePointer(to: &t.c_cc) { p in
                p.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { ccp in
                    ccp[Int(VMIN)] = 0
                    ccp[Int(VTIME)] = 1
                }
            }
            _ = tcsetattr(fd, TCSAFLUSH, &t)
        }
    }

    private func restoreTermiosIfNeeded() async {
        let fd = input.fileDescriptor
        guard var orig = originalTermios else { return }
        _ = tcsetattr(fd, TCSAFLUSH, &orig)
        originalTermios = nil
    }

    private func readLoop() async {
        let fd = input.fileDescriptor
        var buf = [UInt8](repeating: 0, count: 1024)
        while !Task.isCancelled {
            #if os(Linux)
            let n = Glibc.read(fd, &buf, buf.count)
            #else
            let n = Darwin.read(fd, &buf, buf.count)
            #endif
            if n > 0 {
                await process(bytes: Array(buf[0..<Int(n)]))
            } else if n == 0 {
                break // EOF
            } else {
                // sleep briefly to avoid spin on EAGAIN/interrupt
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    // Decode as many complete events as possible from buffer
    private func decodeFromBuffer() async {
        while !buffer.isEmpty {
            if await handleBracketedPasteIfNeeded() { continue }
            if await handleImmediateControlIfNeeded() { continue }
            if await handlePasteStartIfNeeded() { continue }
            if await handleEscapedSequencesIfNeeded() { continue }
            // Fallback: if ESC may start a sequence, wait for more; otherwise consume one byte
            if buffer.first == 0x1B { break }
            buffer.removeFirst()
        }
    }

    // Split helpers to reduce cyclomatic complexity
    private func handleBracketedPasteIfNeeded() async -> Bool {
        if isInBracketedPaste {
            if let endRange = searchCSI(param: "201~", in: buffer) {
                let endStart = endRange.lowerBound
                pasteBuffer.append(contentsOf: buffer[..<endStart])
                buffer.removeFirst(endRange.upperBound)
                let text = String(decoding: pasteBuffer, as: UTF8.self)
                pasteBuffer.removeAll(keepingCapacity: true)
                isInBracketedPaste = false
                await emit(.paste(text))
                return true
            } else {
                pasteBuffer.append(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                return true // wait for more
            }
        }
        return false
    }

    private func handleImmediateControlIfNeeded() async -> Bool {
        if let first = buffer.first, (first == 0x03 || first == 0x04) {
            let ctrl = first == 0x03 ? KeyEvent.ctrlC : KeyEvent.ctrlD
            buffer.removeFirst()
            await emit(ctrl)
            return true
        }
        return false
    }

    private func handlePasteStartIfNeeded() async -> Bool {
        if let startRange = searchCSI(param: "200~", in: buffer) {
            isInBracketedPaste = true
            pasteBuffer.removeAll(keepingCapacity: true)
            buffer.removeFirst(startRange.upperBound)
            return true
        }
        return false
    }

    private func handleEscapedSequencesIfNeeded() async -> Bool {
        guard let first = buffer.first, first == 0x1B else { return false }
        if buffer.count < 2 { return false }
        let second = buffer[1]
        if buffer.count >= 3 {
            if second == 0x5B { // '[', CSI
                if let (consumed, event) = parseCSI(buffer) {
                    buffer.removeFirst(consumed)
                    if let ev = event { await emit(ev) }
                    return true
                } else {
                    // Incomplete CSI, wait for more
                    return false
                }
            } else if second == 0x4F { // 'O', SS3
                if let (consumed, event) = parseSS3(buffer) {
                    buffer.removeFirst(consumed)
                    if let ev = event { await emit(ev) }
                    return true
                } else {
                    return false
                }
            }
        } else {
            // We have ESC followed by a single byte; if it's '[' or 'O', it's likely a
            // CSI/SS3 sequence in progress — wait for more data instead of consuming.
            if second == 0x5B || second == 0x4F { return false }
        }

        // Unknown ESC sequence, consume ESC only
        buffer.removeFirst()
        return true
    }

    // Parse CSI sequences like ESC [ 1 ; 5 A or ESC [ 5 ~
    private func parseCSI(_ bytes: [UInt8]) -> (Int, KeyEvent?)? {
        // Find final byte in A–Z or ~
        var i = 2
        while i < bytes.count {
            let ch = bytes[i]
            if (65...90).contains(Int(ch)) || ch == 0x7E { // 'A'..'Z' or '~'
                // Parse parameters (if any) between '[' and final
                let paramsBytes = bytes[2..<i]
                let params = String(decoding: paramsBytes, as: UTF8.self)
                    .split(separator: ";")
                    .compactMap { Int($0) }
                let final = ch
                if let ev = mapCSI(params: params, final: final) {
                    return (i + 1, ev)
                } else {
                    return (i + 1, nil)
                }
            }
            i += 1
        }
        return nil // incomplete
    }

    private func mapCSI(params: [Int], final: UInt8) -> KeyEvent? {
        switch final {
        case 0x41, 0x42, 0x43, 0x44: // Arrows A..D
            return mapArrow(final: final, params: params)
        case 0x48: // H Home
            let m = params.count >= 2 ? modsFrom(code: params.last!) : []
            return .key(kind: .home, modifiers: m)
        case 0x46: // F End
            let m = params.count >= 2 ? modsFrom(code: params.last!) : []
            return .key(kind: .end, modifiers: m)
        case 0x7E: // ~ family
            return mapTildeFamily(params: params)
        default:
            return nil
        }
    }

    private func modsFrom(code: Int) -> KeyModifiers {
        // xterm: 1+shift(1)+alt(2)+ctrl(4)
        let m = code - 1
        var out: KeyModifiers = []
        if (m & 1) != 0 { out.insert(.shift) }
        if (m & 2) != 0 { out.insert(.alt) }
        if (m & 4) != 0 { out.insert(.ctrl) }
        return out
    }

    private func mapArrow(final: UInt8, params: [Int]) -> KeyEvent? {
        if let last = params.last, params.count >= 2 {
            let mods = modsFrom(code: last)
            switch final {
            case 0x41: return .key(kind: .up, modifiers: mods)
            case 0x42: return .key(kind: .down, modifiers: mods)
            case 0x43: return .key(kind: .right, modifiers: mods)
            case 0x44: return .key(kind: .left, modifiers: mods)
            default: return nil
            }
        }
        switch final {
        case 0x41: return .arrowUp
        case 0x42: return .arrowDown
        case 0x43: return .arrowRight
        case 0x44: return .arrowLeft
        default: return nil
        }
    }

    private func mapTildeFamily(params: [Int]) -> KeyEvent? {
        guard let code = params.first else { return nil }
        let m = params.count >= 2 ? modsFrom(code: params.last!) : []
        switch code {
        case 5: return .key(kind: .pageUp, modifiers: m)
        case 6: return .key(kind: .pageDown, modifiers: m)
        case 15: return .key(kind: .function(5), modifiers: m)
        case 17: return .key(kind: .function(6), modifiers: m)
        case 18: return .key(kind: .function(7), modifiers: m)
        case 19: return .key(kind: .function(8), modifiers: m)
        case 20: return .key(kind: .function(9), modifiers: m)
        case 21: return .key(kind: .function(10), modifiers: m)
        case 23: return .key(kind: .function(11), modifiers: m)
        case 24: return .key(kind: .function(12), modifiers: m)
        default: return nil
        }
    }

    // Parse SS3 sequences like ESC O A, ESC O P (F1)
    private func parseSS3(_ bytes: [UInt8]) -> (Int, KeyEvent?)? {
        guard bytes.count >= 3 else { return nil }
        let final = bytes[2]
        let consumed = 3
        switch final {
        case 0x41: return (consumed, .arrowUp)  // Up
        case 0x42: return (consumed, .arrowDown)
        case 0x43: return (consumed, .arrowRight)
        case 0x44: return (consumed, .arrowLeft)
        case 0x48: return (consumed, .key(kind: .home, modifiers: [])) // OH sometimes used
        case 0x46: return (consumed, .key(kind: .end, modifiers: []))  // OF sometimes used
        case 0x50: return (consumed, .key(kind: .function(1), modifiers: [])) // OP
        case 0x51: return (consumed, .key(kind: .function(2), modifiers: [])) // OQ
        case 0x52: return (consumed, .key(kind: .function(3), modifiers: [])) // OR
        case 0x53: return (consumed, .key(kind: .function(4), modifiers: [])) // OS
        default: return (consumed, nil)
        }
    }

    // Find CSI ESC [ <param> starting at any position; return range [start,end)
    private func searchCSI(param: String, in bytes: [UInt8]) -> Range<Int>? {
        let pat: [UInt8] = [0x1B, 0x5B] + Array(param.utf8)
        guard bytes.count >= pat.count else { return nil }
        var i = 0
        while i + pat.count <= bytes.count {
            if Array(bytes[i..<(i + pat.count)]) == pat {
                return i..<(i + pat.count)
            }
            i += 1
        }
        return nil
    }
}


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
    case tab
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
    /// Convenience alias for a plain Tab key event
    public static var tabKey: KeyEvent { .key(kind: .tab, modifiers: []) }

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
    private let closeControlOutOnStop: Bool

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

    // Lookup tables to keep mapping logic simple (lower cyclomatic complexity)
    private static let arrowKindMap: [UInt8: KeyKind] = [
        0x41: .up,    // A
        0x42: .down,  // B
        0x43: .right, // C
        0x44: .left   // D
    ]

    private static let tildeKindMap: [Int: KeyKind] = [
        5: .pageUp,
        6: .pageDown,
        15: .function(5),
        17: .function(6),
        18: .function(7),
        19: .function(8),
        20: .function(9),
        21: .function(10),
        23: .function(11),
        24: .function(12)
    ]

    private static let ss3Map: [UInt8: KeyEvent] = [
        0x41: .arrowUp,
        0x42: .arrowDown,
        0x43: .arrowRight,
        0x44: .arrowLeft,
        0x48: .key(kind: .home, modifiers: []),
        0x46: .key(kind: .end, modifiers: []),
        0x50: .key(kind: .function(1), modifiers: []),
        0x51: .key(kind: .function(2), modifiers: []),
        0x52: .key(kind: .function(3), modifiers: []),
        0x53: .key(kind: .function(4), modifiers: [])
    ]

    public init(
        input: FileHandle,
        controlOut: FileHandle,
        enableRawMode: Bool,
        enableBracketedPaste: Bool,
        exitOnCtrlC: Bool,
        closeControlOutOnStop: Bool = false
    ) {
        self.input = input
        self.controlOut = controlOut
        self.enableRawMode = enableRawMode
        self.enableBracketedPaste = enableBracketedPaste
        self.exitOnCtrlC = exitOnCtrlC
        self.closeControlOutOnStop = closeControlOutOnStop
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
        // Close controlOut if we created a dup specifically for this session (Linux pipe EOF hygiene)
        if closeControlOutOnStop {
            do { try controlOut.close() } catch { /* ignore */ }
        }
    }

    // MARK: - Testing hooks / direct processing

    /// Directly feed bytes into the decoder (used by tests or when the caller handles I/O)
    public func process(bytes: [UInt8]) async {
        buffer.append(contentsOf: bytes)
        await decodeFromBuffer()
    }

    // MARK: - Private helpers

    private func emit(_ event: KeyEvent) async { await handler?(event) }

    private func writeControl(_ control: String) {
        if let data = control.data(using: .utf8) { controlOut.write(data) }
    }

    private func isATTY(_ fd: Int32) -> Int32 { isatty(fd) }

    private func enableRawModeIfTTY() async {
        let fd = input.fileDescriptor
        guard isATTY(fd) == 1 else { return }
        var term = termios()
        if tcgetattr(fd, &term) == 0 {
            originalTermios = term
            cfmakeraw(&term)
            // Set VMIN/VTIME: non-blocking-ish read with 100ms timeout
            withUnsafeMutablePointer(to: &term.c_cc) { ctrlArrayPtr in
                ctrlArrayPtr.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { ccp in
                    ccp[Int(VMIN)] = 0
                    ccp[Int(VTIME)] = 1
                }
            }
            _ = tcsetattr(fd, TCSAFLUSH, &term)
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
            let bytesRead = Glibc.read(fd, &buf, buf.count)
            #else
            let bytesRead = Darwin.read(fd, &buf, buf.count)
            #endif
            if bytesRead > 0 {
                await process(bytes: Array(buf[0..<Int(bytesRead)]))
            } else if bytesRead == 0 {
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
            if await handleTabIfNeeded() { continue }
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
                // Intentionally allow lossy decoding for paste content which may contain arbitrary bytes
                // swiftlint:disable:next optional_data_string_conversion
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

    private func handleTabIfNeeded() async -> Bool {
        if let first = buffer.first, first == 0x09 { // HT (Tab)
            buffer.removeFirst()
            await emit(.key(kind: .tab, modifiers: []))
            return true
        }
        return false
    }

    private func handleImmediateControlIfNeeded() async -> Bool {
        if let first = buffer.first, first == 0x03 || first == 0x04 {
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
                // swiftlint:disable:next optional_data_string_conversion
                let paramsString = String(decoding: paramsBytes, as: UTF8.self)
                let params = paramsString
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
        case 0x5A: // CSI Z is often sent for Shift+Tab
            // Map to tab with shift modifier via KeyKind.tab
            return .key(kind: .tab, modifiers: [.shift])
        case 0x41, 0x42, 0x43, 0x44: // Arrows A..D
            return mapArrow(final: final, params: params)
        case 0x48: // H Home
            let mods = params.count >= 2 ? modsFrom(code: params.last!) : []
            return .key(kind: .home, modifiers: mods)
        case 0x46: // F End
            let mods = params.count >= 2 ? modsFrom(code: params.last!) : []
            return .key(kind: .end, modifiers: mods)
        case 0x7E: // ~ family
            return mapTildeFamily(params: params)
        default:
            return nil
        }
    }

    private func modsFrom(code: Int) -> KeyModifiers {
        // xterm: 1+shift(1)+alt(2)+ctrl(4)
        let mask = code - 1
        var mods: KeyModifiers = []
        if (mask & 1) != 0 { mods.insert(.shift) }
        if (mask & 2) != 0 { mods.insert(.alt) }
        if (mask & 4) != 0 { mods.insert(.ctrl) }
        return mods
    }

    private func mapArrow(final: UInt8, params: [Int]) -> KeyEvent? {
        // With modifiers (CSI 1;5A etc.)
        if let last = params.last, params.count >= 2 {
            guard let kind = Self.arrowKindMap[final] else { return nil }
            let mods = modsFrom(code: last)
            return .key(kind: kind, modifiers: mods)
        }
        // Legacy arrows without modifiers
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
        let mods = params.count >= 2 ? modsFrom(code: params.last!) : []
        guard let kind = Self.tildeKindMap[code] else { return nil }
        return .key(kind: kind, modifiers: mods)
    }

    // Parse SS3 sequences like ESC O A, ESC O P (F1)
    private func parseSS3(_ bytes: [UInt8]) -> (Int, KeyEvent?)? {
        guard bytes.count >= 3 else { return nil }
        let final = bytes[2]
        let consumed = 3
        if let ev = Self.ss3Map[final] {
            return (consumed, ev)
        }
        return (consumed, nil)
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

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// I/O related hooks: useStdin/useStdout/useStderr and their metadata
/// Split from Hooks.swift to uphold single responsibility and match component organization
public enum IOHooks {
    /// Streams + metadata snapshot for hooks access. FileHandles are not Sendable; mark container unchecked.
    public final class Streams: @unchecked Sendable {
        public let stdin: FileHandle
        public let stdout: FileHandle
        public let stderr: FileHandle
        public let stdinIsTTY: Bool
        public let stdoutIsTTY: Bool
        public let stderrIsTTY: Bool
        public let stdinIsRawMode: Bool
        public init(stdin: FileHandle, stdout: FileHandle, stderr: FileHandle,
                    stdinIsTTY: Bool, stdoutIsTTY: Bool, stderrIsTTY: Bool,
                    stdinIsRawMode: Bool) {
            self.stdin = stdin
            self.stdout = stdout
            self.stderr = stderr
            self.stdinIsTTY = stdinIsTTY
            self.stdoutIsTTY = stdoutIsTTY
            self.stderrIsTTY = stderrIsTTY
            self.stdinIsRawMode = stdinIsRawMode
        }
    }

    // Public data structs returned by hooks
    public struct StdinInfo { public let handle: FileHandle; public let isTTY: Bool; public let isRawMode: Bool }
    public struct StdoutInfo { public let handle: FileHandle; public let isTTY: Bool }
    public struct StderrInfo { public let handle: FileHandle; public let isTTY: Bool }
}

// Keep the user-facing hooks under HooksRuntime for a consistent API surface
public extension HooksRuntime {
    /// I/O streams context bound by the runtime during build/render and effect commits
    @TaskLocal static var ioStreams: IOHooks.Streams?

    /// Expose configured stdin stream and metadata
    static func useStdin() -> IOHooks.StdinInfo {
        if let streams = ioStreams {
            return IOHooks.StdinInfo(handle: streams.stdin, isTTY: streams.stdinIsTTY, isRawMode: streams.stdinIsRawMode)
        }
        let isTty = isatty(STDIN_FILENO) == 1
        return IOHooks.StdinInfo(handle: FileHandle.standardInput, isTTY: isTty, isRawMode: false)
    }

    /// Expose configured stdout stream and metadata
    static func useStdout() -> IOHooks.StdoutInfo {
        if let streams = ioStreams {
            return IOHooks.StdoutInfo(handle: streams.stdout, isTTY: streams.stdoutIsTTY)
        }
        let isTty = isatty(STDOUT_FILENO) == 1
        return IOHooks.StdoutInfo(handle: FileHandle.standardOutput, isTTY: isTty)
    }

    /// Expose configured stderr stream and metadata
    static func useStderr() -> IOHooks.StderrInfo {
        if let streams = ioStreams {
            return IOHooks.StderrInfo(handle: streams.stderr, isTTY: streams.stderrIsTTY)
        }
        let isTty = isatty(STDERR_FILENO) == 1
        return IOHooks.StderrInfo(handle: FileHandle.standardError, isTTY: isTty)
    }
}

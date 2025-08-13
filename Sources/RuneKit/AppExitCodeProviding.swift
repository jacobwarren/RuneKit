import Foundation

/// Types that provide an exit code for application termination
public protocol AppExitCodeProviding {
    var exitCode: Int32 { get }
}

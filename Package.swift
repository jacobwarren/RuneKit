// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RuneKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        // Main library product - umbrella module
        .library(
            name: "RuneKit",
            targets: ["RuneKit"]
        ),

        // Individual module products for advanced users
        .library(
            name: "RuneANSI",
            targets: ["RuneANSI"]
        ),
        .library(
            name: "RuneUnicode",
            targets: ["RuneUnicode"]
        ),
        .library(
            name: "RuneLayout",
            targets: ["RuneLayout"]
        ),
        .library(
            name: "RuneRenderer",
            targets: ["RuneRenderer"]
        ),
        .library(
            name: "RuneComponents",
            targets: ["RuneComponents"]
        ),

        // CLI executable for examples and demos
        .executable(
            name: "RuneCLI",
            targets: ["RuneCLI"]
        ),
    ],
    dependencies: [
        // Yoga layout engine for flexbox implementation
        .package(url: "https://github.com/facebook/yoga.git", from: "3.2.1")
    ],
    targets: [
        // System library for utf8proc
        .systemLibrary(
            name: "Cutf8proc",
            pkgConfig: "libutf8proc",
            providers: [
                .brew(["utf8proc"]),
                .apt(["libutf8proc-dev"])
            ]
        ),

        // Core modules - foundational layers
        .target(
            name: "RuneANSI",
            dependencies: ["RuneUnicode"]
        ),
        .target(
            name: "RuneUnicode",
            dependencies: ["Cutf8proc"]
        ),
        .target(
            name: "RuneLayout",
            dependencies: [
                "RuneUnicode",
                .product(name: "yoga", package: "yoga")
            ]
        ),

        // Rendering layer
        .target(
            name: "RuneRenderer",
            dependencies: ["RuneANSI", "RuneUnicode"]
        ),

        // Component layer
        .target(
            name: "RuneComponents",
            dependencies: ["RuneLayout", "RuneRenderer"]
        ),

        // Main umbrella module
        .target(
            name: "RuneKit",
            dependencies: [
                "RuneANSI",
                "RuneUnicode",
                "RuneLayout",
                "RuneRenderer",
                "RuneComponents"
            ]
        ),

        // Shared test support (pure Swift utilities for tests)
        .target(
            name: "TestSupport",
            dependencies: [],
            path: "Sources/TestSupport"
        ),

        // CLI executable
        .executableTarget(
            name: "RuneCLI",
            dependencies: ["RuneKit"]
        ),

        // Test targets
        .testTarget(
            name: "RuneANSITests",
            dependencies: ["RuneANSI"]
        ),
        .testTarget(
            name: "RuneUnicodeTests",
            dependencies: ["RuneUnicode"]
        ),
        .testTarget(
            name: "RuneLayoutTests",
            dependencies: ["RuneLayout"]
        ),
        .testTarget(
            name: "RuneRendererTests",
            dependencies: ["RuneRenderer", "TestSupport"]
        ),
        .testTarget(
            name: "RuneComponentsTests",
            dependencies: ["RuneComponents", "TestSupport"]
        ),
        .testTarget(
            name: "RuneKitTests",
            dependencies: ["RuneKit"]
        ),
    ]
)

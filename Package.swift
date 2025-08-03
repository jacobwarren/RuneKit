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
    targets: [
        // Core modules - foundational layers
        .target(
            name: "RuneANSI",
            dependencies: []
        ),
        .target(
            name: "RuneUnicode",
            dependencies: []
        ),
        .target(
            name: "RuneLayout",
            dependencies: ["RuneUnicode"]
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
            dependencies: ["RuneRenderer"]
        ),
        .testTarget(
            name: "RuneComponentsTests",
            dependencies: ["RuneComponents"]
        ),
        .testTarget(
            name: "RuneKitTests",
            dependencies: ["RuneKit"]
        ),
    ]
)

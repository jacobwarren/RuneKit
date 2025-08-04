// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EmojiTest",
    dependencies: [
        .package(path: ".")
    ],
    targets: [
        .executableTarget(
            name: "EmojiTest",
            dependencies: ["RuneUnicode"],
            path: ".",
            sources: ["test_emoji_main.swift"]
        )
    ]
)

// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Island",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/MrKai77/DynamicNotchKit", from: "1.1.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Island",
            dependencies: ["DynamicNotchKit", "KeyboardShortcuts"],
            path: "Sources/Island"
        ),
        .testTarget(
            name: "IslandTests",
            dependencies: ["Island"],
            path: "Tests/IslandTests"
        )
    ]
)

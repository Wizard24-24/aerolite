// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AeroLite",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AeroLite",
            path: "Sources/AeroLite",
            swiftSettings: [.unsafeFlags(["-swift-version", "5"])]
        )
    ]
)

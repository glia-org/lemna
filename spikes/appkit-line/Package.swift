// swift-tools-version: 6.2
// appkit-line: the AppKit half of the sliding-line spike (../SPEC.md). No package dependencies.
import PackageDescription

let package = Package(
    name: "appkit-line",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:)
    targets: [
        .target(name: "LineCore"),
        .executableTarget(name: "appkit-line", dependencies: ["LineCore"]),
        .testTarget(name: "LineCoreTests", dependencies: ["LineCore"]),
    ],
    swiftLanguageModes: [.v5]
)

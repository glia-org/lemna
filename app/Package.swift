// swift-tools-version: 6.2
// Flow (working name): the writing surface. FlowCore holds the text model and the line's geometry free of AppKit, so
// `swift test` checks them without a window; Flow is the AppKit app. No package dependencies (DESIGN.md T2).
import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:), NSApplication.activate()
    targets: [
        .target(name: "FlowCore"),
        .executableTarget(name: "Flow", dependencies: ["FlowCore"]),
        .testTarget(name: "FlowCoreTests", dependencies: ["FlowCore"]),
    ],
    swiftLanguageModes: [.v5]
)

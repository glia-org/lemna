// swift-tools-version: 6.2
// FlowClicks: the key click player (DESIGN.md K1). No package dependencies.
import PackageDescription

let package = Package(
    name: "FlowClicks",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FlowClicks", targets: ["FlowClicks"])],
    targets: [
        // C11 atomics for the key-to-audio-thread hand-off: Swift's own Atomic needs macOS 15.
        .target(name: "ClickRing"),
        // The packs are copied into an app's Contents/Resources, not SwiftPM resources (README, Adding a pack).
        .target(name: "FlowClicks", dependencies: ["ClickRing"],
                exclude: ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack"]),
        .testTarget(name: "FlowClicksTests", dependencies: ["FlowClicks"]),
    ],
    swiftLanguageModes: [.v5]
)

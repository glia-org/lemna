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
        .target(name: "FlowClicks", dependencies: ["ClickRing"], resources: [.copy("DefaultPack")]),
        .testTarget(name: "FlowClicksTests", dependencies: ["FlowClicks"]),
    ],
    swiftLanguageModes: [.v5]
)

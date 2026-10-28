// swift-tools-version: 6.2
// LemnaClicks: the key click player (DESIGN.md K1). No package dependencies.
import PackageDescription

let package = Package(
    name: "LemnaClicks",
    platforms: [.macOS(.v14)],
    products: [.library(name: "LemnaClicks", targets: ["LemnaClicks"])],
    targets: [
        // C11 atomics for the key-to-audio-thread hand-off: Swift's own Atomic needs macOS 15.
        .target(name: "ClickRing"),
        // The packs are copied into an app's Contents/Resources, not SwiftPM resources (README, Adding a pack).
        .target(name: "LemnaClicks", dependencies: ["ClickRing"],
                exclude: ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack"]),
        .testTarget(name: "LemnaClicksTests", dependencies: ["LemnaClicks"]),
    ],
    swiftLanguageModes: [.v5]
)

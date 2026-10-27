// swift-tools-version: 6.2
// Flow (working name): the writing surface. FlowCore holds the text model, the line's geometry, the mechanical pass and
// the session's end free of AppKit, so `swift test` checks them without a window; Flow is the AppKit app. The two
// dependencies are next door: the journal (DESIGN.md T2, E2) and, for the app alone, the click player (K1).
import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:), NSApplication.activate()
    dependencies: [.package(path: "../lib/FlowJournal"), .package(path: "../lib/FlowClicks")],
    targets: [
        .target(name: "FlowCore", dependencies: [.product(name: "FlowJournal", package: "FlowJournal")]),
        .executableTarget(name: "Flow",
                          dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal"),
                                         .product(name: "FlowClicks", package: "FlowClicks")]),
        .testTarget(name: "FlowCoreTests",
                    dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal")]),
    ],
    swiftLanguageModes: [.v5]
)

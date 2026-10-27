// swift-tools-version: 6.2
// Flow (working name): the writing surface. FlowCore holds the text model, the line's geometry, the mechanical pass and
// the session's end free of AppKit, so `swift test` checks them without a window; Flow is the AppKit app. The one
// dependency is the journal next door (DESIGN.md T2, E2).
import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:), NSApplication.activate()
    dependencies: [.package(path: "../lib/FlowJournal")],
    targets: [
        .target(name: "FlowCore", dependencies: [.product(name: "FlowJournal", package: "FlowJournal")]),
        .executableTarget(name: "Flow",
                          dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal")]),
        .testTarget(name: "FlowCoreTests",
                    dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal")]),
    ],
    swiftLanguageModes: [.v5]
)

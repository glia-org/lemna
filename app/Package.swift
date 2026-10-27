// swift-tools-version: 6.2
// Flow (working name): the writing surface. FlowCore holds the text model, the line's geometry, the mechanical pass,
// Harper's suggestions as plain values and the session's end free of AppKit (and of Harper), so `swift test` checks
// them without a window; Flow is the AppKit app. The dependencies are next door: the journal (DESIGN.md T2, E2), and
// for the app the click player (K1) and Harper (R2). The tests link Harper too, for the lint through the real library.
// Harper is a Rust static library: cargo builds it first and the build command says where it is (make-app.sh,
// README.md; ../lib/FlowHarper/README.md, Linking).
import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:), NSApplication.activate()
    dependencies: [.package(path: "../lib/FlowJournal"), .package(path: "../lib/FlowClicks"),
                   .package(path: "../lib/FlowHarper")],
    targets: [
        .target(name: "FlowCore", dependencies: [.product(name: "FlowJournal", package: "FlowJournal")]),
        .executableTarget(name: "Flow",
                          dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal"),
                                         .product(name: "FlowClicks", package: "FlowClicks"),
                                         .product(name: "FlowHarper", package: "FlowHarper")]),
        .testTarget(name: "FlowCoreTests",
                    dependencies: ["FlowCore", .product(name: "FlowJournal", package: "FlowJournal"),
                                   .product(name: "FlowHarper", package: "FlowHarper")]),
    ],
    swiftLanguageModes: [.v5]
)

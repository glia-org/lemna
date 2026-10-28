// swift-tools-version: 6.2
// Lemna: the writing surface. LemnaCore holds the text model, the line's geometry, the mechanical pass and
// the session's end free of AppKit, so `swift test` checks them without a window; Lemna is the AppKit app. The two
// dependencies are next door: the journal (DESIGN.md T2, E2) and, for the app alone, the click player (K1). LemnaCatch
// is one Objective-C function that catches an Objective-C exception, which Swift cannot (A1: the ambience's display
// link).
import PackageDescription

let package = Package(
    name: "Lemna",
    platforms: [.macOS(.v14)],  // NSView.displayLink(target:selector:), NSApplication.activate()
    dependencies: [.package(path: "../lib/LemnaJournal"), .package(path: "../lib/LemnaClicks")],
    targets: [
        .target(name: "LemnaCore", dependencies: [.product(name: "LemnaJournal", package: "LemnaJournal")]),
        .target(name: "LemnaCatch"),
        .executableTarget(name: "Lemna",
                          dependencies: ["LemnaCore", "LemnaCatch", .product(name: "LemnaJournal", package: "LemnaJournal"),
                                         .product(name: "LemnaClicks", package: "LemnaClicks")]),
        .testTarget(name: "LemnaCoreTests",
                    dependencies: ["LemnaCore", "LemnaCatch", .product(name: "LemnaJournal", package: "LemnaJournal")]),
    ],
    swiftLanguageModes: [.v5]
)

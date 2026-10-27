// swift-tools-version: 6.2
// FlowJournal: the never-lose, private journal (../../DESIGN.md E2). No package dependencies.
import PackageDescription

let package = Package(
    name: "FlowJournal",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FlowJournal", targets: ["FlowJournal"])],
    targets: [
        .target(name: "FlowJournal"),
        // Not a product: the kill -9 test runs it as a child process and kills it mid-session.
        .executableTarget(name: "journal-kill-helper", dependencies: ["FlowJournal"]),
        // The Command Line Tools 26.1 ship _Testing_Foundation.framework without its Modules folder, so a file that
        // imports Testing and Foundation fails with "no such module '_Testing_Foundation'". The tests need neither
        // that overlay nor Xcode; no dependent builds this target.
        .testTarget(name: "FlowJournalTests", dependencies: ["FlowJournal"],
                    swiftSettings: [.unsafeFlags(["-Xfrontend", "-disable-cross-import-overlays"])]),
    ],
    swiftLanguageModes: [.v5]
)

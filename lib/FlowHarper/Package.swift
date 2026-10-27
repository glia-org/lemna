// swift-tools-version: 6.2
// FlowHarper: offline English grammar and spelling suggestions for the review (../../DESIGN.md R2), from Harper's
// harper-core built in rust/ as a static library. No package dependencies. build.sh builds both halves.
import PackageDescription

let package = Package(
    name: "FlowHarper",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FlowHarper", targets: ["FlowHarper"])],
    targets: [
        // The C ABI (include/flow_harper.h). Its module map links libflow_harper.a, found through the -L that the
        // build command passes: a linker flag here would have to be unsafeFlags (README, "Linking").
        .systemLibrary(name: "CFlowHarper", path: "include"),
        .target(name: "FlowHarper", dependencies: ["CFlowHarper"]),
        .testTarget(name: "FlowHarperTests", dependencies: ["FlowHarper"]),
    ],
    swiftLanguageModes: [.v5]
)

// swift-tools-version: 5.9
import PackageDescription

/// Workspace entry point. Production targets live in a local package so an Xcode
/// workspace can depend on it without allowing the app target to bypass module boundaries.
let package = Package(
    name: "SentinelOpsWorkspace",
    platforms: [.iOS(.v17)],
    products: [],
    dependencies: [.package(path: "Packages/SentinelOps")],
    targets: []
)

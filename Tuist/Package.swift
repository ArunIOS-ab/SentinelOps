// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

/// Tuist resolves this manifest into Xcode-compatible package products.
let packageSettings = PackageSettings(
    productTypes: [
        "GRDB": .framework
    ]
)
#endif

let package = Package(
    name: "SentinelOpsDependencies",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.3")
    ]
)

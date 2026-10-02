// swift-tools-version: 5.9
import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .unsafeFlags(["-warn-concurrency", "-strict-concurrency=complete"])
]

let package = Package(
    name: "SentinelOps",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AppShell", targets: ["AppShell"]),
        .library(name: "CaptureFeature", targets: ["CaptureFeature"]),
        .library(name: "SyncFeature", targets: ["SyncFeature"]),
        .library(name: "IncidentFeature", targets: ["IncidentFeature"]),
        .library(name: "AIInferenceEngine", targets: ["AIInferenceEngine"]),
        .library(name: "SyncEngine", targets: ["SyncEngine"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
        .library(name: "CoreUI", targets: ["CoreUI"])
    ],
    targets: [
        .target(name: "CoreDomain", swiftSettings: strictConcurrency),
        .target(name: "CoreUI", dependencies: ["CoreDomain"], swiftSettings: strictConcurrency),
        .target(name: "Persistence", dependencies: ["CoreDomain"], swiftSettings: strictConcurrency),
        .target(name: "Networking", dependencies: ["CoreDomain"], swiftSettings: strictConcurrency),
        .target(name: "AIInferenceEngine", dependencies: ["CoreDomain"], swiftSettings: strictConcurrency),
        .target(name: "SyncEngine", dependencies: ["CoreDomain", "Persistence", "Networking"], swiftSettings: strictConcurrency),
        .target(name: "CaptureFeature", dependencies: ["CoreDomain", "CoreUI", "AIInferenceEngine", "Persistence"], swiftSettings: strictConcurrency),
        .target(name: "SyncFeature", dependencies: ["CoreDomain", "CoreUI", "SyncEngine"], swiftSettings: strictConcurrency),
        .target(name: "IncidentFeature", dependencies: ["CoreDomain", "CoreUI", "Persistence"], swiftSettings: strictConcurrency),
        .target(
            name: "AppShell",
            dependencies: ["CoreDomain", "CoreUI", "Persistence", "Networking", "AIInferenceEngine", "SyncEngine", "CaptureFeature", "SyncFeature", "IncidentFeature"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(name: "CoreDomainTests", dependencies: ["CoreDomain"], swiftSettings: strictConcurrency),
        .testTarget(name: "SyncEngineTests", dependencies: ["SyncEngine", "CoreDomain"], swiftSettings: strictConcurrency)
    ]
)

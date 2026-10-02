// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SentinelOps",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
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
    dependencies: [],
    targets: [
        // MARK: - Core Domain Layer
        .target(
            name: "CoreDomain",
            dependencies: [],
            path: "Sources/CoreDomain",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Core UI & Design System
        .target(
            name: "CoreUI",
            dependencies: ["CoreDomain"],
            path: "Sources/CoreUI",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Persistence Layer
        .target(
            name: "Persistence",
            dependencies: ["CoreDomain"],
            path: "Sources/Persistence",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Networking Layer
        .target(
            name: "Networking",
            dependencies: ["CoreDomain"],
            path: "Sources/Networking",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - AI Inference Engine
        .target(
            name: "AIInferenceEngine",
            dependencies: ["CoreDomain"],
            path: "Sources/AIInferenceEngine",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Sync Engine
        .target(
            name: "SyncEngine",
            dependencies: ["CoreDomain", "Persistence", "Networking"],
            path: "Sources/SyncEngine",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Features
        .target(
            name: "CaptureFeature",
            dependencies: ["CoreDomain", "CoreUI", "AIInferenceEngine"],
            path: "Sources/Features/CaptureFeature",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        .target(
            name: "SyncFeature",
            dependencies: ["CoreDomain", "CoreUI", "SyncEngine"],
            path: "Sources/Features/SyncFeature",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        .target(
            name: "IncidentFeature",
            dependencies: ["CoreDomain", "CoreUI", "Persistence"],
            path: "Sources/Features/IncidentFeature",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - App Shell
        .target(
            name: "AppShell",
            dependencies: [
                "CoreDomain",
                "CoreUI",
                "Persistence",
                "Networking",
                "AIInferenceEngine",
                "SyncEngine",
                "CaptureFeature",
                "SyncFeature",
                "IncidentFeature"
            ],
            path: "Sources/AppShell",
            swiftSettings: [
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        
        // MARK: - Tests
        .testTarget(
            name: "CoreDomainTests",
            dependencies: ["CoreDomain"],
            path: "Tests/CoreDomainTests"
        ),
        
        .testTarget(
            name: "SyncEngineTests",
            dependencies: ["SyncEngine", "CoreDomain"],
            path: "Tests/SyncEngineTests"
        )
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SentinelOps",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "AppShell", targets: ["AppShell"]),
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
        .library(name: "CoreUI", targets: ["CoreUI"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "SyncEngine", targets: ["SyncEngine"]),
        .library(name: "AIInference", targets: ["AIInference"]),
        .library(name: "AIPrivacyPolicy", targets: ["AIPrivacyPolicy"])
    ],
    targets: [
        .target(name: "CoreDomain", path: "Sources/CoreDomain"),
        .target(name: "CoreUI", dependencies: ["CoreDomain"], path: "Sources/CoreUI"),
        .target(name: "Persistence", dependencies: ["CoreDomain"], path: "Sources/Persistence"),
        .target(name: "Networking", dependencies: ["CoreDomain"], path: "Sources/Networking"),
        .target(name: "SyncEngine", dependencies: ["CoreDomain", "Persistence", "Networking", "AIPrivacyPolicy"], path: "Sources/SyncEngine"),
        .target(name: "AIInference", dependencies: ["CoreDomain", "AIPrivacyPolicy"], path: "Sources/AIInference"),
        .target(name: "AIPrivacyPolicy", dependencies: ["CoreDomain"], path: "Sources/AIPrivacyPolicy"),
        .target(name: "AppShell", dependencies: ["CoreDomain", "CoreUI", "Persistence", "Networking", "SyncEngine", "AIInference", "AIPrivacyPolicy"], path: "Sources/AppShell"),
        .testTarget(name: "CoreDomainTests", dependencies: ["CoreDomain"], path: "Tests/CoreDomainTests")
    ]
)

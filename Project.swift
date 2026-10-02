import ProjectDescription

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "5.9",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "OTHER_SWIFT_FLAGS": "$(inherited) -warn-concurrency -strict-concurrency=complete"
]

let configurations: [Configuration] = [
    .debug(name: "Debug", settings: [
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG SENTINELOPS_TESTING"
    ]),
    .debug(name: "Staging", settings: [
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "STAGING SENTINELOPS_TESTING"
    ]),
    .release(name: "Release", settings: [
        "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
        "SWIFT_COMPILATION_MODE": "wholemodule"
    ])
]

let projectSettings = Settings.settings(base: baseSettings, configurations: configurations)
let destinations: Destinations = [.iPhone, .iPad]

let appInfoPlist: [String: Plist.Value] = [
    "CFBundleDisplayName": "SentinelOps",
    "NSCameraUsageDescription": "SentinelOps uses the camera to capture safety evidence and identify hazards.",
    "NSLocationWhenInUseUsageDescription": "SentinelOps uses your location to associate an inspection with its work site.",
    "UIBackgroundModes": .array([.string("fetch"), .string("processing")]),
    "BGTaskSchedulerPermittedIdentifiers": .array([.string("com.sentinelops.backgroundsync")]),
    "UISupportedInterfaceOrientations": .array([
        .string("UIInterfaceOrientationPortrait"),
        .string("UIInterfaceOrientationLandscapeLeft"),
        .string("UIInterfaceOrientationLandscapeRight")
    ]),
    "UISupportedInterfaceOrientations~ipad": .array([
        .string("UIInterfaceOrientationPortrait"),
        .string("UIInterfaceOrientationPortraitUpsideDown"),
        .string("UIInterfaceOrientationLandscapeLeft"),
        .string("UIInterfaceOrientationLandscapeRight")
    ])
]

func frameworkTarget(
    name: String,
    bundleID: String,
    dependencies: [TargetDependency] = []
) -> Target {
    Target(
        name: name,
        destinations: destinations,
        product: .framework,
        bundleId: bundleID,
        deploymentTargets: .iOS("17.0"),
        infoPlist: .default,
        sources: ["Targets/\(name)/Sources/**"],
        resources: ["Targets/\(name)/Resources/**"],
        dependencies: dependencies,
        settings: projectSettings
    )
}

let project = Project(
    name: "SentinelOps",
    organizationName: "com.sentinelops",
    settings: projectSettings,
    targets: [
        frameworkTarget(name: "CoreDomain", bundleID: "com.sentinelops.coredomain"),
        frameworkTarget(
            name: "CoreUI",
            bundleID: "com.sentinelops.coreui",
            dependencies: [.target(name: "CoreDomain")]
        ),
        frameworkTarget(
            name: "AIInferenceEngine",
            bundleID: "com.sentinelops.aiengine",
            dependencies: [.target(name: "CoreDomain")]
        ),
        frameworkTarget(
            name: "SyncEngine",
            bundleID: "com.sentinelops.syncengine",
            dependencies: [
                .target(name: "CoreDomain"),
                .package(product: "GRDB")
            ]
        ),
        frameworkTarget(
            name: "AppShell",
            bundleID: "com.sentinelops.appshell",
            dependencies: [
                .target(name: "CoreDomain"),
                .target(name: "CoreUI"),
                .target(name: "AIInferenceEngine"),
                .target(name: "SyncEngine")
            ]
        ),
        Target(
            name: "SentinelOps",
            destinations: destinations,
            product: .app,
            bundleId: "com.sentinelops.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: appInfoPlist),
            sources: ["Targets/SentinelOps/Sources/**"],
            resources: ["Targets/SentinelOps/Resources/**"],
            entitlements: "Targets/SentinelOps/Resources/SentinelOps.entitlements",
            dependencies: [
                .target(name: "AppShell"),
                .target(name: "AIInferenceEngine"),
                .target(name: "SyncEngine"),
                .target(name: "CoreDomain"),
                .target(name: "CoreUI")
            ],
            settings: projectSettings
        ),
        Target(
            name: "SentinelOpsTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "com.sentinelops.app.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Targets/SentinelOpsTests/Sources/**"],
            dependencies: [
                .target(name: "SentinelOps"),
                .target(name: "CoreDomain"),
                .target(name: "SyncEngine")
            ],
            settings: projectSettings
        )
    ],
    schemes: [
        Scheme.scheme(
            name: "SentinelOps",
            shared: true,
            buildAction: .buildAction(targets: ["SentinelOps"]),
            testAction: .targets(
                ["SentinelOpsTests"],
                configuration: "Debug",
                options: .options(codeCoverage: true)
            ),
            runAction: .runAction(
                configuration: "Debug",
                executable: "SentinelOps",
                arguments: .arguments(environmentVariables: [
                    "SENTINELOPS_TEST_MODE": "YES",
                    "SENTINELOPS_DISABLE_REMOTE_SYNC": "YES"
                ])
            ),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)

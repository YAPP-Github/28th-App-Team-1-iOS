import ProjectDescription

// MARK: — Helpers

private let bundlePrefix = "com.architecture"
private let deployment = Destinations.iOS
private let iOSVersion = "17.0"

private func framework(
    name: String,
    sourcesPath: String,
    resources: ResourceFileElements? = nil,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: name,
        destinations: deployment,
        product: .framework,
        bundleId: "\(bundlePrefix).\(name)",
        deploymentTargets: .iOS(iOSVersion),
        sources: ["\(sourcesPath)/**"],
        resources: resources,
        dependencies: dependencies
    )
}

private func unitTests(
    name: String,
    sourcesPath: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: name,
        destinations: deployment,
        product: .unitTests,
        bundleId: "\(bundlePrefix).\(name)",
        deploymentTargets: .iOS(iOSVersion),
        sources: ["\(sourcesPath)/**"],
        dependencies: dependencies
    )
}

// MARK: — Project

let project = Project(
    name: "Architecture",
    targets: [
        // ── App ───────────────────────────────────────────────
        .target(
            name: "Architecture",
            destinations: deployment,
            product: .app,
            bundleId: "\(bundlePrefix).app",
            deploymentTargets: .iOS(iOSVersion),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: ["Architecture/**"],
            resources: ["Architecture/Assets.xcassets"],
            dependencies: [
                .target(name: "AppFeature")
            ]
        ),

        // ── AppFeature (탭 코디네이터, DocC) ───────────────────
        framework(
            name: "AppFeature",
            sourcesPath: "Projects/App/AppFeature/Sources",
            resources: ["Projects/App/AppFeature/AppFeature.docc/**"],
            dependencies: [
                .target(name: "HomeFeature"),
                .target(name: "UserFeature"),
                .target(name: "ActivityFeature"),
                .target(name: "ProfileFeature"),
                .target(name: "UserClientLive"),
                .target(name: "ProfileClientLive"),
                .external(name: "ComposableArchitecture")
            ]
        ),

        // ── Data : UserClient (Interface + Live, MFA 적용) ────
        framework(
            name: "UserClientInterface",
            sourcesPath: "Projects/Data/UserClient/Interface",
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "Models")
            ]
        ),
        framework(
            name: "UserClientLive",
            sourcesPath: "Projects/Data/UserClient/Live",
            dependencies: [
                .target(name: "UserClientInterface"),
                .external(name: "ComposableArchitecture"),
                .external(name: "Models")
            ]
        ),

        // ── Data : ProfileClient (Interface + Live, MFA 적용) ─
        framework(
            name: "ProfileClientInterface",
            sourcesPath: "Projects/Data/ProfileClient/Interface",
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "Models")
            ]
        ),
        framework(
            name: "ProfileClientLive",
            sourcesPath: "Projects/Data/ProfileClient/Live",
            dependencies: [
                .target(name: "ProfileClientInterface"),
                .external(name: "ComposableArchitecture"),
                .external(name: "Models")
            ]
        ),

        // ── Feature : HomeFeature (Sources + Tests + Testing) ─
        framework(
            name: "HomeFeature",
            sourcesPath: "Projects/Feature/HomeFeature/Sources",
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "DesignSystemKit")
            ]
        ),
        framework(
            name: "HomeFeatureTesting",
            sourcesPath: "Projects/Feature/HomeFeature/Testing",
            dependencies: [
                .target(name: "HomeFeature")
            ]
        ),
        unitTests(
            name: "HomeFeatureTests",
            sourcesPath: "Projects/Feature/HomeFeature/Tests",
            dependencies: [
                .target(name: "HomeFeature"),
                .target(name: "HomeFeatureTesting"),
                .external(name: "ComposableArchitecture")
            ]
        ),

        // ── Feature : UserFeature ─────────────────────────────
        framework(
            name: "UserFeature",
            sourcesPath: "Projects/Feature/UserFeature/Sources",
            dependencies: [
                .target(name: "UserClientInterface"),
                .target(name: "ProfileFeature"),
                .external(name: "ComposableArchitecture"),
                .external(name: "Models"),
                .external(name: "DesignSystemKit")
            ]
        ),
        framework(
            name: "UserFeatureTesting",
            sourcesPath: "Projects/Feature/UserFeature/Testing",
            dependencies: [
                .target(name: "UserFeature")
            ]
        ),
        unitTests(
            name: "UserFeatureTests",
            sourcesPath: "Projects/Feature/UserFeature/Tests",
            dependencies: [
                .target(name: "UserFeature"),
                .target(name: "UserFeatureTesting"),
                .external(name: "ComposableArchitecture")
            ]
        ),

        // ── Feature : ActivityFeature ─────────────────────────
        framework(
            name: "ActivityFeature",
            sourcesPath: "Projects/Feature/ActivityFeature/Sources",
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "DesignSystemKit")
            ]
        ),
        framework(
            name: "ActivityFeatureTesting",
            sourcesPath: "Projects/Feature/ActivityFeature/Testing",
            dependencies: [
                .target(name: "ActivityFeature")
            ]
        ),
        unitTests(
            name: "ActivityFeatureTests",
            sourcesPath: "Projects/Feature/ActivityFeature/Tests",
            dependencies: [
                .target(name: "ActivityFeature"),
                .target(name: "ActivityFeatureTesting"),
                .external(name: "ComposableArchitecture")
            ]
        ),

        // ── Feature : ProfileFeature ──────────────────────────
        framework(
            name: "ProfileFeature",
            sourcesPath: "Projects/Feature/ProfileFeature/Sources",
            dependencies: [
                .target(name: "ProfileClientInterface"),
                .external(name: "ComposableArchitecture"),
                .external(name: "Models"),
                .external(name: "DesignSystemKit")
            ]
        ),
        framework(
            name: "ProfileFeatureTesting",
            sourcesPath: "Projects/Feature/ProfileFeature/Testing",
            dependencies: [
                .target(name: "ProfileFeature")
            ]
        ),
        unitTests(
            name: "ProfileFeatureTests",
            sourcesPath: "Projects/Feature/ProfileFeature/Tests",
            dependencies: [
                .target(name: "ProfileFeature"),
                .target(name: "ProfileFeatureTesting"),
                .external(name: "ComposableArchitecture")
            ]
        )
    ]
)

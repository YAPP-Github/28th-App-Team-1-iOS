import ProjectDescription

let project = Project(
    name: "HomeFeature",
    targets: [
        // MARK: — Interface (학습용 placeholder)
        .target(
            name: "HomeFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.HomeFeatureInterface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/**"]
        ),

        // MARK: — Sources (실제 Reducer + View)
        .target(
            name: "HomeFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.HomeFeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .target(name: "HomeFeatureInterface"),
                .external(name: "ComposableArchitecture"),
                .external(name: "DesignSystemKit")
            ]
        ),

        // MARK: — Testing (다른 모듈 테스트에서 쓸 mock)
        .target(
            name: "HomeFeatureTesting",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.HomeFeatureTesting",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/**"],
            dependencies: [
                .target(name: "HomeFeatureInterface")
            ]
        ),

        // MARK: — Tests
        .target(
            name: "HomeFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.architecture.HomeFeatureTests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "HomeFeature"),
                .target(name: "HomeFeatureTesting"),
                .external(name: "ComposableArchitecture")
            ]
        )
    ]
)

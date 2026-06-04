import ProjectDescription

let project = Project(
    name: "Architecture",
    targets: [
        .target(
            name: "Architecture",
            destinations: .iOS,
            product: .app,
            bundleId: "com.architecture.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: ["Architecture/**"],
            resources: ["Architecture/Assets.xcassets"],
            dependencies: [
                .project(target: "AppFeature", path: "Projects/App/AppFeature")
            ]
        )
    ]
)

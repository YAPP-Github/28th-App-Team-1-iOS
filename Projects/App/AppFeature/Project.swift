import ProjectDescription

let project = Project(
    name: "AppFeature",
    targets: [
        .target(
            name: "AppFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.AppFeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: ["AppFeature.docc/**"],
            dependencies: [
                .project(target: "HomeFeature", path: "../../Feature/HomeFeature"),
                .external(name: "ComposableArchitecture"),
                .external(name: "UserFeature"),
                .external(name: "ActivityFeature"),
                .external(name: "ProfileFeature")
            ]
        )
    ]
)

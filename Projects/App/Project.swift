import ProjectDescription
import ProjectDescriptionHelpers

// App 프로젝트 = composition root.
//   • Architecture(.app) : 진입점. *ClientLive 를 link 해 liveValue 활성화.
//   • AppFeature         : 탭 코디네이터 + cross-feature 라우팅.
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
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .target(name: "AppFeature"),
                .clientLive("User"),
                .clientLive("Profile"),
                .clientLive("Activity")
            ]
        ),
        .target(
            name: "AppFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.appfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["AppFeature/Sources/**"],
            resources: ["AppFeature/AppFeature.docc/**"],
            dependencies: [
                .feature("Home"),
                .feature("Users"),
                .feature("Profile"),
                .feature("Activity"),
                .models,
                .composableArchitecture
            ]
        )
    ]
)

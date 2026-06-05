import ProjectDescription
import ProjectDescriptionHelpers

// App 프로젝트 = composition root.
//   • Architecture(.app)  : 진입점. *ClientLive 를 link 해 liveValue 활성화.
//   • AppFeature          : 탭 코디네이터 + cross-feature 라우팅.
//   • ArchitectureDocs    : 프로젝트 전역 DocC 카탈로그 전용 호스트 (코드 없음).
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
            scripts: [.swiftLint],
            dependencies: [
                .feature("Home"),
                .feature("Users"),
                .feature("Profile"),
                .feature("Activity"),
                .models,
                .composableArchitecture
            ]
        ),
        // 프로젝트 전역 문서 전용 타겟. 실행 코드 없음(빈 모듈) — 카탈로그만 호스팅한다.
        // 심볼 링크(``HomeFeature`` 등) 해결을 위해 문서가 참조하는 모듈을 모두 의존한다.
        .target(
            name: "ArchitectureDocs",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.architecture.docs",
            deploymentTargets: .iOS("17.0"),
            sources: ["Documentation/Sources/**"],
            resources: ["Documentation/Architecture.docc/**"],
            dependencies: [
                .target(name: "AppFeature"),
                .feature("Home"),
                .feature("Users"),
                .feature("Profile"),
                .feature("Activity"),
                .models,
                .designSystemKit,
                .composableArchitecture
            ]
        )
    ]
)

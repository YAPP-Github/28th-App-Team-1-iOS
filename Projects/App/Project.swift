import ProjectDescription
import ProjectDescriptionHelpers

// App 프로젝트 = composition root.
//   • Architecture(.app)  : 진입점. *ClientLive 를 link 해 liveValue 활성화.
//   • AppFeature          : 탭 코디네이터 + cross-feature 라우팅.
//   • ArchitectureDocs    : 프로젝트 전역 DocC 카탈로그 전용 호스트 (코드 없음).
let project = Project(
    name: "Architecture",
    // 환경 분리: Dev / QA / Release 3단계. 각 xcconfig 가 APP_ENV·API_BASE_URL·번들ID 주입.
    // 이름·타입(Dev=.debug / QA=.debug / Release=.release)은 워크스페이스 전역(Settings.standard)과 일치해야 한다.
    //   • Dev: 개발계 서버 + 디버그 메뉴(DEV 컴파일 조건)  • QA: 개발계 서버, 디버그 메뉴 없음  • Release: 운영계
    settings: .settings(
        configurations: [
            .debug(
                name: "Dev",
                settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEV"],
                xcconfig: "Config/Dev.xcconfig"
            ),
            .debug(name: "QA", xcconfig: "Config/QA.xcconfig"),
            .release(name: "Release", xcconfig: "Config/Prod.xcconfig")
        ]
    ),
    targets: [
        .target(
            name: "Architecture",
            destinations: .iOS,
            product: .app,
            // 접미사는 xcconfig(BUNDLE_ID_SUFFIX)가 결정 — 개발계 .dev / 운영계 빈값.
            bundleId: "com.yapp01.architecture.app$(BUNDLE_ID_SUFFIX)",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                // xcconfig → Info.plist 치환. AppConfig.fromBundle() 가 읽는다.
                "APP_ENV": "$(APP_ENV)",
                "API_BASE_URL": "$(API_BASE_URL)",
                "CFBundleDisplayName": "$(APP_DISPLAY_NAME)"
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .target(name: "AppFeature"),
                .appConfig,
                .domainLive("User"),
                .domainLive("Profile"),
                .domainLive("Activity")
            ]
        ),
        .target(
            name: "AppFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.yapp01.architecture.appfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["AppFeature/Sources/**"],
            scripts: [.swiftLint],
            dependencies: [
                .feature("Home"),
                .feature("Users"),
                .feature("Profile"),
                .feature("Activity"),
                .domainInterface("Profile"),
                .composableArchitecture
            ]
        ),
        // 프로젝트 전역 문서 전용 타겟. 실행 코드 없음(빈 모듈) — 카탈로그만 호스팅한다.
        // 심볼 링크(``HomeFeature`` 등) 해결을 위해 문서가 참조하는 모듈을 모두 의존한다.
        .target(
            name: "ArchitectureDocs",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.yapp01.architecture.docs",
            deploymentTargets: .iOS("17.0"),
            sources: ["Documentation/Sources/**"],
            resources: ["Documentation/Architecture.docc/**"],
            dependencies: [
                .target(name: "AppFeature"),
                .feature("Home"),
                .feature("Users"),
                .feature("Profile"),
                .feature("Activity"),
                .domainInterface("User"),
                .domainInterface("Profile"),
                .domainInterface("Activity"),
                .designSystemKit,
                .appConfig,
                .composableArchitecture
            ]
        )
    ],
    schemes: [
        // 개발계 — Dev 구성(디버그 메뉴 포함)으로 실행/아카이브.
        .scheme(
            name: "Architecture-Dev",
            shared: true,
            buildAction: .buildAction(targets: ["Architecture"]),
            runAction: .runAction(configuration: .configuration("Dev"), executable: "Architecture"),
            archiveAction: .archiveAction(configuration: .configuration("Dev"))
        ),
        // QA — 개발계 서버, 디버그 메뉴 없음. 테스터 배포(아카이브)용.
        .scheme(
            name: "Architecture-QA",
            shared: true,
            buildAction: .buildAction(targets: ["Architecture"]),
            runAction: .runAction(configuration: .configuration("QA"), executable: "Architecture"),
            archiveAction: .archiveAction(configuration: .configuration("QA"))
        ),
        // 운영계 — Release 구성으로 실행/아카이브.
        .scheme(
            name: "Architecture-Prod",
            shared: true,
            buildAction: .buildAction(targets: ["Architecture"]),
            runAction: .runAction(configuration: .release, executable: "Architecture"),
            archiveAction: .archiveAction(configuration: .release)
        )
    ]
)

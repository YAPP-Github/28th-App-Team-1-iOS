import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Hilit",
    // 자동 스킴(Run=Dev/Archive=Release 혼합)을 끄고 아래 환경별 스킴만 노출한다 — QA 실행·아카이브 경로 확보.
    options: .options(automaticSchemesOptions: .disabled),
    targets: [
        .app(factory: .init(dependencies: [
            .core, .domain, .feature, .shared,
            .core(interface: .common),           // 첫 실행 판정 — FirstLaunchStore
            .core(interface: .network),          // AppView 전역 로딩 — NetworkActivity 관찰 · 첫 실행 정리 — TokenStore
            .domain(interface: .appVersion),     // Splash 버전 게이트 — 강제·권장 업데이트 판정
            .domain(interface: .auth),
            .domain(interface: .consent),        // Splash 세션 복구 판정 — 게이트 2단(pending)
            .domain(interface: .interview),      // 진행 중 면접 두 갈래 — 중단·재개 호출 + held 세션 보관
            .shared(interface: .designSystem),   // AppView 전역 로딩 — LoadingModal 표출
            .composableArchitecture
        ])),
        // 전역 DocC 카탈로그 호스트 (코드 없음). Xcode: 스킴 ArchitectureDocs → Product → Build Documentation
        .docs(factory: .init(dependencies: [
            .core, .domain, .feature, .shared,
            .composableArchitecture
        ]))
    ],
    schemes: [
        // 환경별 앱 스킴 — Run/Archive 가 같은 계(Configuration)를 가리킨다. → DocC Environments
        .app(name: "Hilit-Dev", configuration: "Dev"),
        .app(name: "Hilit-QA", configuration: "QA"),
        .app(name: "Hilit-Prod", configuration: "Release"),
        .scheme(
            name: "ArchitectureDocs",
            shared: true,
            buildAction: .buildAction(targets: ["ArchitectureDocs"])
        )
    ]
)

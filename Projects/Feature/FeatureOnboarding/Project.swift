import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureOnboarding",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Onboarding", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .job),
            .domain(interface: .jd),
            .domain(interface: .portfolio),
            .domain(interface: .interview),   // 분석 스텝: 세션 생성(S0~S3 일괄 수집)
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "Onboarding"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다 —
        // 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .feature(tests: "Onboarding", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .job),
            .domain(interface: .jd),
            .domain(interface: .portfolio),
            .domain(interface: .interview)
        ])),
        // Example = 온보딩 단독 데모 앱. 가짜 의존성으로 네트워크 없이 위저드 전체를 돌린다.
        // TestFlight 배포 타겟도 겸한다 → 이미 등록된 dev 앱(com.hilit.app.dev)을 재활용해 올린다.
        // ⚠️ 본체 Hilit 의 Dev 빌드와 Bundle ID 가 겹친다 — "온보딩 데모만 TestFlight 에 올리고,
        //    본체 dev 는 TestFlight/실기기에 올리지 않는다"는 전제. 한 기기엔 둘 중 하나만 설치된다.
        // TODO: dev 번들 재활용은 임시 절충. 다음 중 하나가 생기면 Example 전용 번들
        //       (com.hilit.app.onboarding 등)로 분리 + App Store Connect 앱 신규 등록으로 전환할 것.
        //       ① 본체 Hilit-Dev 를 TestFlight/실기기에 올려야 할 때
        //       ② 온보딩이 앱에 정식 통합되어 이 데모 배포가 불필요해질 때
        .feature(example: "Onboarding", factory: .init(
            bundleId: "com.hilit.app.dev",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIUserInterfaceStyle": "Light",
                "CFBundleDisplayName": "Hilit 온보딩",
                // 버전은 아래 settings 의 빌드 세팅에서 치환된다.
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                // 온보딩 데모는 네트워크·암호화 미사용 → TestFlight 업로드 시 수출규정 질문 스킵.
                "ITSAppUsesNonExemptEncryption": false
            ]),
            dependencies: [
                .composableArchitecture,
                .domain(interface: .job),
                .domain(interface: .jd),
                .domain(interface: .portfolio),
                .domain(interface: .interview)
            ],
            settings: .settings(
                base: [
                    // -all_load 는 팩토리(compositionRootSettings) 관례 유지 (D4). Example 은 가짜 의존성이라 무해.
                    "OTHER_LDFLAGS": "$(inherited) -all_load",
                    // dev 앱 레코드의 TestFlight 빌드 트랙. 업로드마다 CURRENT_PROJECT_VERSION 을 올린다.
                    "MARKETING_VERSION": "0.0.1",
                    "CURRENT_PROJECT_VERSION": "1",
                    "CODE_SIGN_STYLE": "Automatic"
                ],
                // 서명 팀(DEVELOPMENT_TEAM)을 Secrets.xcconfig 에서 주입 — generate 마다 팀이 리셋되는 걸 막는다.
                // Onboarding.xcconfig 가 Secrets 를 옵셔널 include (본체 Hilit 과 동일 방식).
                configurations: [
                    .debug(name: "Dev", xcconfig: "Config/Onboarding.xcconfig"),
                    .release(name: "QA", xcconfig: "Config/Onboarding.xcconfig"),
                    .release(name: "Release", xcconfig: "Config/Onboarding.xcconfig")
                ]
            )
        )),
    ],
    schemes: [
        // 온보딩 데모 TestFlight 배포 스킴 — build/archive 를 Example 앱·Release 로 고정한다.
        // (개발 실행용 자동 스킴 FeatureOnboarding 은 그대로 유지된다.)
        .scheme(
            name: "Hilit-Onboarding",
            shared: true,
            buildAction: .buildAction(targets: ["FeatureOnboardingExample"]),
            runAction: .runAction(configuration: "Release", executable: "FeatureOnboardingExample"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release", executable: "FeatureOnboardingExample"),
            analyzeAction: .analyzeAction(configuration: "Release")
        )
    ]
)

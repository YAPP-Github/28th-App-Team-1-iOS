import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureInterview",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Interview", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interview),
            .domain(interface: .permission),
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "Interview"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다 —
        // 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .feature(tests: "Interview", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interview),
            .domain(interface: .permission)
        ])),
        .feature(example: "Interview", factory: .init(
            // 기본 example plist(feature(example:) 팩토리)를 오버라이드하므로 기본 키를 함께 유지한다.
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "NSAppTransportSecurity": ["NSAllowsArbitraryLoads": true],
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "CFBundleIconName": "AppIcon",
                // 카메라·마이크는 사용 시점 요청(ai-interview.md §권한) — 목적 문구 없으면 요청 즉시 크래시.
                "NSCameraUsageDescription": "AI 면접에서 얼굴과 답변 영상 녹화를 위해 카메라를 사용합니다.",
                "NSMicrophoneUsageDescription": "AI 면접에서 음성 답변 인식과 녹음을 위해 마이크를 사용합니다."
            ]),
            dependencies: [
                .composableArchitecture,
                .domain(interface: .interview),
                // 권한만 실물 IO — 준비 화면의 요청→거부 alert→설정 이동 흐름 검증용 (liveValue 활성화).
                .project(target: "DomainPermissionImplementation", path: .domain(.permission))
            ]
        )),
    ]
)

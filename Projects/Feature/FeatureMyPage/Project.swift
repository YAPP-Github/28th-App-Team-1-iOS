import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureMyPage",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "MyPage", factory: .init(dependencies: [
            .composableArchitecture,
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "MyPage"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다 —
        // 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .feature(tests: "MyPage", factory: .init(dependencies: [
            .composableArchitecture
        ])),
        .feature(example: "MyPage", factory: .init(
            // 앱 아이콘 — feature(example:) 는 기본 리소스가 없어 명시 안 하면 아이콘 누락(업로드 90713·90022).
            resources: ["Example/Resources/**"],
            dependencies: [
                .composableArchitecture,
                .shared(interface: .designSystem)
            ]
        ))
    ]
)

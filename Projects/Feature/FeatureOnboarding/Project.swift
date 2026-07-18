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
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "Onboarding"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다 —
        // 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .feature(tests: "Onboarding", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .job)
        ])),
        .feature(example: "Onboarding", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .job)
        ])),
    ]
)

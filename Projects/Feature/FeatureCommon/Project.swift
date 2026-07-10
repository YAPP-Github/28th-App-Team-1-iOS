import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureCommon",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Common", factory: .init(dependencies: [
            .domain(interface: .common),      // FeatureImplementation → DomainInterface (비즈니스 로직 사용)
            .domain(interface: .interview),   // NetworkExampleFeature — InterviewClient 계약 (네트워킹 표준 예시)
            .composableArchitecture
        ])),
        .feature(testing: "Common"),
        .feature(tests: "Common", factory: .init(dependencies: [
            .domain(interface: .interview),   // TestStore 에서 InterviewClient 를 스텁
            .composableArchitecture
        ])),
        // Example 도 composition root — umbrella 로 Domain/Core liveValue 를 활성화한다 (D4).
        .feature(example: "Common", factory: .init(dependencies: [
            .domain,
            .core
        ]))
    ]
)

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "FeatureCommon",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Common", factory: .init(dependencies: [
            .domain(interface: .common),    // FeatureImplementation → DomainInterface (비즈니스 로직 사용)
            .composableArchitecture,
        ])),
        .feature(testing: "Common"),
        .feature(tests: "Common"),
        .feature(example: "Common"),
    ]
)

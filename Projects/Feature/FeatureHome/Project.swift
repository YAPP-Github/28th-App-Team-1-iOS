import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureHome",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Home", factory: .init(dependencies: [
            .composableArchitecture,
        ])),
        .feature(testing: "Home"),
        .feature(tests: "Home"),
        .feature(example: "Home"),
    ]
)

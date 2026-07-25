import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureReport",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다.
        .feature(implements: "Report", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interviewReport),
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "Report"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다.
        .feature(tests: "Report", factory: .init(dependencies: [
            .composableArchitecture
        ])),
        .feature(example: "Report")
    ]
)

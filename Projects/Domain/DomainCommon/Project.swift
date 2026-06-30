import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DomainCommon",
    targets: [
        .domain(interface: "Common"),
        .domain(implements: "Common", factory: .init(dependencies: [
            .core(interface: .common),  // DomainImplementation → CoreInterface (인프라 추상화 사용)
        ])),
        .domain(testing: "Common"),
        .domain(tests: "Common"),
    ]
)

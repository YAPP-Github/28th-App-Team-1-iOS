import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "CoreNetwork",
    targets: [
        .core(interface: "Network", factory: .init(dependencies: [
            .composableArchitecture   // NetworkClient 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .core(implements: "Network", factory: .init(dependencies: [
            .composableArchitecture   // liveValue(DependencyKey) 구현
        ])),
        .core(testing: "Network"),
        .core(tests: "Network", factory: .init(dependencies: [
            .composableArchitecture
        ]))
    ]
)

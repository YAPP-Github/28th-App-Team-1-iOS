import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "CoreCommon",
    targets: [
        .core(interface: "Common", factory: .init(dependencies: [
            .composableArchitecture   // FirstLaunchStore 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .core(implements: "Common", factory: .init(dependencies: [
            .composableArchitecture   // liveValue(DependencyKey) 구현
        ])),
        .core(testing: "Common"),
        .core(tests: "Common", factory: .init(dependencies: [
            .composableArchitecture
        ]))
    ]
)

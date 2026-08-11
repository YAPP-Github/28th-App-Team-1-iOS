import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "CoreNetwork",
    targets: [
        .core(interface: "Network", factory: .init(dependencies: [
            .composableArchitecture,  // NetworkClient 계약이 TestDependencyKey/DependencyValues 를 사용
            .core(interface: .common) // 디코딩 실패 로그 게이트 — LogGate
        ])),
        .core(implements: "Network", factory: .init(dependencies: [
            .composableArchitecture,  // liveValue(DependencyKey) 구현
            .core(interface: .common) // 요청/응답 로그 게이트 — LogGate
        ])),
        .core(testing: "Network"),
        .core(tests: "Network", factory: .init(dependencies: [
            .composableArchitecture
        ]))
    ]
)

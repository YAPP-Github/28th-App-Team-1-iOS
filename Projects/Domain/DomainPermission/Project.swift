import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainPermission",
    targets: [
        .domain(interface: "Permission", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .domain(implements: "Permission", factory: .init(dependencies: [
            .composableArchitecture   // liveValue(DependencyKey) 구현 — 서버 IO 없음(AVFoundation 디바이스 권한)
        ])),
        .domain(testing: "Permission"),
        .domain(tests: "Permission"),
    ]
)

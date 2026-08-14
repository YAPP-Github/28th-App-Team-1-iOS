import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainDeeplink",
    targets: [
        .domain(interface: "Deeplink", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .domain(implements: "Deeplink", factory: .init(dependencies: [
            .composableArchitecture,   // liveValue(DependencyKey) 구현
            // 링크 SaaS SDK 는 이 Implementation 안에만 존재한다 — Interface·Feature·App 은 SDK 를 모른다.
            .chottuLinkSDK,
            .core(interface: .common)   // 수신 로그 게이트 — LogGate (deferred 는 화면 단서가 없다)
        ])),
        .domain(testing: "Deeplink"),
        .domain(tests: "Deeplink")
    ]
)

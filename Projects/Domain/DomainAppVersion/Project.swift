import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainAppVersion",
    targets: [
        .domain(interface: "AppVersion", factory: .init(dependencies: [
            .composableArchitecture,      // Client 계약이 TestDependencyKey/DependencyValues 를 사용
            .domain(interface: .common)   // DomainAPIError 채택 (에러 매핑 공통 계약)
        ])),
        .domain(implements: "AppVersion", factory: .init(dependencies: [
            .composableArchitecture,      // liveValue(DependencyKey) 구현
            .core(interface: .network),   // 인프라 추상화(NetworkClient 계약)만 의존 — 구현은 App/Example 이 link
            .domain(interface: .common)   // AppVersionError.mapping (DomainAPIError)
        ])),
        .domain(testing: "AppVersion"),
        .domain(tests: "AppVersion", factory: .init(dependencies: [
            .composableArchitecture   // withDependencies 로 NetworkClient 를 스텁해 liveValue 검증
        ]))
    ]
)

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainConsent",
    targets: [
        .domain(interface: "Consent", factory: .init(dependencies: [
            .composableArchitecture,      // Client 계약이 TestDependencyKey/DependencyValues 를 사용
            .domain(interface: .common)   // DomainAPIError 채택 (에러 매핑 공통 계약)
        ])),
        .domain(implements: "Consent", factory: .init(dependencies: [
            .composableArchitecture,      // liveValue(DependencyKey) 구현
            .core(interface: .network),   // 인프라 추상화(AuthorizedNetworkClient 계약)만 의존 — 구현은 App/Example 이 link
            .domain(interface: .common)   // ConsentError.mapping (DomainAPIError)
        ])),
        .domain(testing: "Consent"),
        .domain(tests: "Consent", factory: .init(dependencies: [
            .composableArchitecture   // withDependencies 로 AuthorizedNetworkClient 를 스텁해 liveValue 검증
        ]))
    ]
)

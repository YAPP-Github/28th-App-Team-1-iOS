import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainInterviewReport",
    targets: [
        .domain(interface: "InterviewReport", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .domain(implements: "InterviewReport", factory: .init(dependencies: [
            .composableArchitecture,     // liveValue(DependencyKey) 구현
            .core(interface: .network)   // 인프라 추상화(AuthorizedNetworkClient 계약)만 의존 — 구현은 App/Example 이 link
        ])),
        .domain(testing: "InterviewReport"),
        .domain(tests: "InterviewReport", factory: .init(dependencies: [
            .composableArchitecture   // withDependencies 로 AuthorizedNetworkClient 를 스텁해 liveValue 검증
        ]))
    ]
)

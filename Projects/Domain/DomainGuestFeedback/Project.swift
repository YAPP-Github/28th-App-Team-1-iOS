import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainGuestFeedback",
    targets: [
        .domain(interface: "GuestFeedback", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .domain(implements: "GuestFeedback", factory: .init(dependencies: [
            .composableArchitecture,     // liveValue(DependencyKey) 구현
            .core(interface: .network)   // 인프라 추상화(NetworkClient 계약)만 의존 — 무인증 API 라 Authorized 불필요
        ])),
        .domain(testing: "GuestFeedback"),
        .domain(tests: "GuestFeedback", factory: .init(dependencies: [
            .composableArchitecture   // withDependencies 로 NetworkClient 를 스텁해 liveValue 검증
        ]))
    ]
)

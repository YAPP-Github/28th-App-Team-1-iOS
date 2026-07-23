import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainFeedback",
    targets: [
        .domain(interface: "Feedback", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .domain(implements: "Feedback", factory: .init(dependencies: [
            .composableArchitecture,     // liveValue(DependencyKey) 구현
            .core(interface: .network)   // 무인증 NetworkClient 계약만 의존 — 구현은 App/Example 이 link
        ])),
        .domain(testing: "Feedback"),
        .domain(tests: "Feedback", factory: .init(dependencies: [
            .composableArchitecture,
            .core(interface: .network)   // Tests 가 NetworkRequest/NetworkError/JSONDecoder.api 를 직접 import
        ]))
    ]
)

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DomainAuth",
    targets: [
        // Interface가 AuthClient(DependencyValues 키) 선언을 위해 TCA를 직접 import 하므로
        // 의존을 명시해야 한다 — 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .domain(interface: "Auth", factory: .init(dependencies: [
            .composableArchitecture
        ])),
        .domain(implements: "Auth", factory: .init(dependencies: [
            .composableArchitecture
        ])),
        .domain(testing: "Auth")
    ]
)

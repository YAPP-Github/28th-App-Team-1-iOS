import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureGuestFeedback",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다.
        .feature(implements: "GuestFeedback", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .feedback),
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "GuestFeedback"),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다.
        .feature(tests: "GuestFeedback", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .feedback),
            .project(target: "DomainFeedbackTesting", path: .domain(.feedback))
        ])),
        .feature(example: "GuestFeedback", factory: .init(
            // TestFlight 배포 대상(G4 단독 검증) — AppIcon 에셋. 없으면 ASC 가 CFBundleIconName 누락으로 거부한다.
            resources: ["Example/Resources/**"],
            dependencies: [
            .composableArchitecture,
            .domain(interface: .feedback),
            .shared(interface: .designSystem),
            .project(target: "DomainFeedbackTesting", path: .domain(.feedback)),
            // 실서버 모드 — liveValue 활성화를 위해 Implementation 은 umbrella 로 link (App/Example 만 허용)
            .domain,
            .core
        ]))
    ]
)

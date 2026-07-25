import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureReport",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다.
        .feature(implements: "Report", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interviewReport),
            .shared(interface: .designSystem)
        ])),
        .feature(testing: "Report", factory: .init(dependencies: [
            .domain(interface: .interviewReport)
        ])),
        // Tests/Example 소스가 직접 import하는 모듈은 전이 의존에 기대지 않고 명시한다 —
        // 누락 시 따뜻한 DerivedData 에서만 우연히 빌드되는 거짓 성공이 난다.
        .feature(tests: "Report", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interviewReport),
            .project(target: "DomainInterviewReportTesting", path: .domain(.interviewReport))
        ])),
        // Example = 리포트 단독 데모. 서버 없이 fixture 를 주입해 화면 분기를 돌린다.
        .feature(example: "Report", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .interviewReport),
            .project(target: "DomainInterviewReportTesting", path: .domain(.interviewReport))
        ]))
    ]
)

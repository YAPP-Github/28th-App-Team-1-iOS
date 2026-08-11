import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DomainCommon",
    targets: [
        .domain(interface: "Common", factory: .init(dependencies: [
            .composableArchitecture,    // 미승격 서버 에러 공통 Alert(serverAlertState) 가 AlertState 를 사용
            .core(interface: .network)  // DomainAPIError 가 ServerError·NetworkError 를 매핑 — 인프라 계약만 의존
        ])),
        .domain(implements: "Common", factory: .init(dependencies: [
            .core(interface: .common)  // DomainImplementation → CoreInterface (인프라 추상화 사용)
        ])),
        .domain(testing: "Common"),
        .domain(tests: "Common", factory: .init(dependencies: [
            .composableArchitecture,    // 공통 Alert(serverAlertState) 검증이 AlertState 를 생성
            .core(interface: .network)  // DomainAPIError 매핑 테스트가 ServerError·NetworkError 를 생성
        ]))
    ]
)

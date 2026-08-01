import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DomainAuth",
    targets: [
        // Interface가 AuthClient(DependencyValues 키) 선언을 위해 TCA를 직접 import 하므로
        // 의존을 명시해야 한다 — 누락 시 따뜻한 DerivedData에서만 우연히 빌드되는 거짓 성공이 난다.
        .domain(interface: "Auth", factory: .init(dependencies: [
            .composableArchitecture,
            .domain(interface: .common),   // DomainAPIError 채택 (에러 매핑 공통 계약)
            .domain(interface: .consent)   // LoginResult.consentStatus — 로그인 응답의 동의 상태(게이트 ①) 타입 공유
        ])),
        .domain(implements: "Auth", factory: .init(dependencies: [
            .composableArchitecture,
            // 카카오 SDK는 이 Implementation 안에만 존재한다 — Interface·Feature·App은 SDK를 모른다.
            .kakaoSDKCommon,
            .kakaoSDKAuth,
            .kakaoSDKUser,
            // 서버 세션 교환(login·refresh·logout) — NetworkClient·TokenStore 계약 (→ lat.md api#Auth)
            .core(interface: .network),
            .domain(interface: .common),   // AuthError.mapping (DomainAPIError)
            .domain(interface: .consent)   // 로그인 응답 consentStatus 디코딩 (ConsentPendingStatus)
        ])),
        .domain(testing: "Auth")
    ]
)

//
//  LoginResult.swift
//  DomainAuthInterface
//
//  Created by EunseoKim on 26/08/01.
//

import DomainConsentInterface

/// 로그인(서버 세션 교환) 응답 중 **앱 진입 라우팅 판정값** — 토큰 페어는 TokenStore 로 들어가고
/// Feature 로는 이 값만 흐른다. 게이트 2단 체인(동의 → 프로필)의 판정 근거다 (docs/work/launch-routing.md).
public struct LoginResult: Equatable, Sendable {
    /// 약관 동의 상태 — 게이트 ①. `upToDate` 가 아니면 약관 화면으로 보낸다
    /// (받을 항목·버전은 응답에 없어 `ConsentClient.pending` 을 따로 부른다).
    public let consentStatus: ConsentPendingStatus
    /// 프로필(이름·직군·연차) 등록 여부 — 게이트 ②. false 면 가입 온보딩(이름부터)으로 보낸다.
    public let profileRegistered: Bool

    public init(consentStatus: ConsentPendingStatus, profileRegistered: Bool) {
        self.consentStatus = consentStatus
        self.profileRegistered = profileRegistered
    }
}

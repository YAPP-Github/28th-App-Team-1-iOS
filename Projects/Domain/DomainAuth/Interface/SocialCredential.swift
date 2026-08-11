//
//  SocialCredential.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

/// 소셜 로그인 성공 시 획득한 자격 증명. provider별 발급물이 다르므로 case로 분리한다.
public enum SocialCredential: Equatable, Sendable {
    /// `accessToken`은 향후 백엔드 연동(`POST /api/v1/auth/social/login`)에 `credential`로 그대로 전송된다.
    /// `refreshToken`은 카카오 SDK `TokenManager`도 자체 보관한다 — 앱은 수신 확인 용도로만 받는다.
    case kakao(accessToken: String, refreshToken: String)
    /// `identityToken`: 백엔드가 서명 검증할 JWT.
    /// `authorizationCode`: 백엔드가 애플 서버와 교환(애플 RT 확보·회원탈퇴 revoke)할
    /// 5분 TTL 일회성 코드 — 이름과 달리 refresh 용도가 아니다.
    case apple(identityToken: String, authorizationCode: String)

    public var provider: SocialProvider {
        switch self {
        case .kakao: .kakao
        case .apple: .apple
        }
    }
}

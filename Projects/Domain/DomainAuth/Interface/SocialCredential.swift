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
    /// `fullName`: 애플이 **최초 인가 1회에만** 주는 이름. 재로그인은 애플 사양상 항상 nil 이라
    /// 소비자는 «없을 수 있음» 을 전제해야 한다. 이메일은 여기 싣지 않는다 — 서버가
    /// authorizationCode 를 교환하며 ID 토큰에서 직접 읽는다(앱이 들고 갈 이유가 없다).
    case apple(identityToken: String, authorizationCode: String, fullName: String?)

    public var provider: SocialProvider {
        switch self {
        case .kakao: .kakao
        case .apple: .apple
        }
    }

    /// 제공자가 함께 준 이름 — 가입 온보딩 이름 입력의 프리필 재료.
    /// 카카오는 계약상 받지 않아 항상 nil 이다(닉네임 동의 항목을 요구하지 않는다).
    public var socialName: String? {
        switch self {
        case .kakao: nil
        case let .apple(_, _, fullName): fullName
        }
    }
}

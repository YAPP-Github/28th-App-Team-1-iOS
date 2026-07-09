/// 소셜 로그인 성공 시 획득한 자격 증명.
/// `accessToken`은 향후 백엔드 연동(`POST /api/v1/auth/social/login`)에 `credential`로 그대로 전송된다.
public struct SocialCredential: Equatable, Sendable {
    public let provider: SocialProvider
    public let accessToken: String

    public init(provider: SocialProvider, accessToken: String) {
        self.provider = provider
        self.accessToken = accessToken
    }
}

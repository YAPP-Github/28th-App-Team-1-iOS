import ComposableArchitecture
import Foundation

/// 인증 파사드. 소셜 로그인 자격증명 획득과 SDK 수명주기 접점(configure·handleOpenURL)을
/// 하나의 seam으로 노출한다. App(조립점)은 lifecycle 이벤트를 이 seam에 연결만 하고,
/// 카카오 SDK는 DomainAuthImplementation(KakaoLoginProvider)에 격리된다.
public struct AuthClient: Sendable {
    /// 앱 시작 시 1회 — 소셜 SDK 초기화. liveValue 사용 전에 선행돼야 한다.
    public var configure: @MainActor @Sendable (_ appKey: String) -> Void
    /// 소셜 로그인 콜백 URL 처리. 카카오 콜백이면 SDK에 전달, 아니면 무시.
    public var handleOpenURL: @MainActor @Sendable (URL) -> Void
    /// 소셜 로그인 → provider가 발급한 AT/RT를 담은 자격증명 반환.
    /// 백엔드 연동 시 이 반환값이 세션 교환의 입력이 된다.
    public var signIn: @Sendable (SocialProvider) async throws -> SocialCredential

    public init(
        configure: @escaping @MainActor @Sendable (_ appKey: String) -> Void,
        handleOpenURL: @escaping @MainActor @Sendable (URL) -> Void,
        signIn: @escaping @Sendable (SocialProvider) async throws -> SocialCredential
    ) {
        self.configure = configure
        self.handleOpenURL = handleOpenURL
        self.signIn = signIn
    }
}

extension AuthClient: TestDependencyKey {}

extension DependencyValues {
    public var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

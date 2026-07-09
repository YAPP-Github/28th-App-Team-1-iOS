import ComposableArchitecture
import Foundation

public struct AuthClient: Sendable {
    public var signInWithKakao: @Sendable () async throws -> SocialCredential
    // 애플 로그인 추가 시: public var signInWithApple: @Sendable () async throws -> SocialCredential

    public init(signInWithKakao: @escaping @Sendable () async throws -> SocialCredential) {
        self.signInWithKakao = signInWithKakao
    }
}

extension AuthClient: TestDependencyKey {}

extension DependencyValues {
    public var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

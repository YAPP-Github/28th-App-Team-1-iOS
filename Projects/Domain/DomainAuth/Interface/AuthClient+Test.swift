import ComposableArchitecture

extension AuthClient {
    public static let testValue = AuthClient(
        signInWithKakao: unimplemented("AuthClient.signInWithKakao")
    )

    public static let previewValue = AuthClient(
        signInWithKakao: {
            SocialCredential(provider: .kakao, accessToken: "preview-access-token")
        }
    )
}

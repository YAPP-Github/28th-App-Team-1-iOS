import ComposableArchitecture

extension AuthClient {
    public static let testValue = AuthClient(
        configure: unimplemented("AuthClient.configure"),
        handleOpenURL: unimplemented("AuthClient.handleOpenURL"),
        signIn: unimplemented("AuthClient.signIn")
    )

    public static let previewValue = AuthClient(
        configure: { _ in },
        handleOpenURL: { _ in },
        signIn: { _ in
            SocialCredential(
                provider: .kakao,
                accessToken: "preview-access-token",
                refreshToken: "preview-refresh-token"
            )
        }
    )
}

//
//  AuthClient+Test.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

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
        signIn: { provider in
            switch provider {
            case .kakao:
                .kakao(
                    accessToken: "preview-access-token",
                    refreshToken: "preview-refresh-token"
                )
            case .apple:
                .apple(
                    identityToken: "preview-identity-token",
                    authorizationCode: "preview-authorization-code"
                )
            }
        }
    )
}

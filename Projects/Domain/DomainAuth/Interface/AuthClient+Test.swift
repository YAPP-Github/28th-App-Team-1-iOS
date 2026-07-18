//
//  AuthClient+Test.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import Foundation

extension AuthClient {
    public static let testValue = AuthClient(
        configure: unimplemented("AuthClient.configure"),
        handleOpenURL: unimplemented("AuthClient.handleOpenURL"),
        signIn: unimplemented("AuthClient.signIn"),
        login: unimplemented("AuthClient.login"),
        refresh: unimplemented("AuthClient.refresh"),
        logout: unimplemented("AuthClient.logout"),
        check: unimplemented("AuthClient.check"),
        isAuthenticated: unimplemented("AuthClient.isAuthenticated", placeholder: false)
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
        },
        login: { _ in },
        refresh: {},
        logout: {},
        check: { AuthCheck(message: "인증 성공", userId: UUID()) },
        isAuthenticated: { true }
    )
}

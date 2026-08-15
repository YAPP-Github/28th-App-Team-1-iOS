//
//  AuthClient+Test.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainConsentInterface
import Foundation

extension AuthClient {
    public static let testValue = AuthClient(
        configure: unimplemented("AuthClient.configure"),
        handleOpenURL: unimplemented("AuthClient.handleOpenURL"),
        signIn: unimplemented("AuthClient.signIn"),
        login: unimplemented("AuthClient.login"),
        loginWithReviewCode: unimplemented("AuthClient.loginWithReviewCode"),
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
                    authorizationCode: "preview-authorization-code",
                    fullName: "서정원"
                )
            }
        },
        // 신규 취급(최초 동의·프로필 미등록) — 프리뷰·Example 이 가입 플로우 전체를 밟게 한다.
        login: { _ in LoginResult(consentStatus: .notSubmitted, profileRegistered: false) },
        // 심사용 코드는 반대로 기존 회원 취급 — 실서버 데모 계정이 온보딩을 마친 상태라 그 판정값을 흉내낸다.
        loginWithReviewCode: { _ in LoginResult(consentStatus: .upToDate, profileRegistered: true) },
        refresh: {},
        logout: {},
        check: { AuthCheck(message: "인증 성공", userId: UUID()) },
        isAuthenticated: { true }
    )
}

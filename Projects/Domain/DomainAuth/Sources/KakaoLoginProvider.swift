//
//  KakaoLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import DomainAuthInterface
import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser


@MainActor
final class KakaoLoginProvider: SocialLoginProvider {
    static func configure(appKey: String) {
        KakaoSDK.initSDK(appKey: appKey)
    }

    static func handleOpenURL(_ url: URL) {
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
        _ = AuthController.handleOpenUrl(url: url)
    }

    func performLogin() async throws -> SocialCredential {
        do {
            let token = try await requestOAuthToken()
            return .kakao(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken
            )
        } catch {
            throw Self.mapKakaoError(error)
        }
    }

    private static func mapKakaoError(_ error: Error) -> AuthError {
        switch error {
        case SdkError.ClientFailed(reason: .Cancelled, _),
            SdkError.AuthFailed(reason: .AccessDenied,_):
            return .cancelled
        case SdkError.AuthFailed(reason: .ServerError, _):
            return .serverUnavailable
        case is URLError:
            return .networkFailure
        default:
            return .unexpected
        }
    }

    private func requestOAuthToken() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AuthError.unexpected)
                }
            }
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
    }
}

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

/// 카카오 로그인 SDK 연동. SDK 타입(OAuthToken·SdkError)은 이 파일 밖으로 나가지 않는다.
///
/// 클래스 전체를 메인 액터에 격리한다 — `UserApi.isKakaoTalkLoginAvailable()`(canOpenURL),
/// `loginWithKakaoTalk`(→`UIApplication.shared.open`), `loginWithKakaoAccount`
/// (→`ASWebAuthenticationSession.start()`)는 SDK가 내부에서 메인 디스패치를 보장하지 않는
/// main-thread-only API라 `.run`(cooperative thread pool)에서 직접 호출하면 안 된다.
/// 부가효과로 `SocialLoginProvider`(Sendable-refining)를 암시적으로 만족시킨다.
@MainActor
final class KakaoLoginProvider: SocialLoginProvider {
    /// 앱 시작 시 1회. AuthClient.liveValue 사용 전에 선행돼야 한다.
    static func configure(appKey: String) {
        KakaoSDK.initSDK(appKey: appKey)
    }

    /// onOpenURL 경유. 카카오 콜백 URL이면 SDK에 전달한다.
    static func handleOpenURL(_ url: URL) {
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
        _ = AuthController.handleOpenUrl(url: url)
    }

    func performLogin() async throws -> SocialCredential {
        do {
            let token = try await requestOAuthToken()
            return SocialCredential(
                provider: .kakao,
                accessToken: token.accessToken,
                refreshToken: token.refreshToken
            )
        } catch {
            // SDK 원본 에러는 도메인 경계 밖으로 내보내지 않는다 — AuthError로 정규화.
            throw Self.mapKakaoError(error)
        }
    }

    /// 취소만 구분하고 나머지는 .unexpected — State가 다르게 반응해야 하는 경우의 수만 유지.
    private static func mapKakaoError(_ error: Error) -> AuthError {
        if let sdkError = error as? SdkError,
           case .ClientFailed(reason: .Cancelled, errorMessage: _) = sdkError {
            return .cancelled
        }
        return .unexpected
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

//
//  AppleLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/12.
//

import AuthenticationServices
import DomainAuthInterface
import Foundation
import UIKit

/// 애플 로그인 연동. ASAuthorization 타입은 이 파일 밖으로 나가지 않는다.
///
/// 클래스 전체를 메인 액터에 격리한다 — `performRequests()`가 시스템 로그인 시트를
/// 제시하는 main-thread-only UI API라 `.run`(cooperative thread pool)에서 직접
/// 호출하면 안 된다(KakaoLoginProvider와 동일 근거). delegate 콜백도 메인 스레드로
/// 도착하므로(애플 샘플 코드가 콜백에서 UI를 직접 갱신) 격리와 정합한다.
@MainActor
final class AppleLoginProvider: NSObject, SocialLoginProvider {
    private var continuation: CheckedContinuation<SocialCredential, Error>?
    private var controller: ASAuthorizationController?

    func performLogin() async throws -> SocialCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            // 이름·이메일을 애플에서 받는다 — 요청하지 않으면 credential 이 둘 다 nil 로 와서
            // 가입 온보딩이 이미 있는 정보를 다시 묻게 된다(App Review Guideline 4 리젝 사유).
            // 이메일은 앱이 쓰지 않지만 scope 로 요청해야 서버가 코드 교환 때 ID 토큰에서 읽을 수 있다.
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    private static func mapAppleError(_ error: Error) -> AuthError {
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            return .cancelled
        }
        return .unexpected
    }

    private func finish(with result: Result<SocialCredential, Error>) {
        switch result {
        case let .success(credential):
            continuation?.resume(returning: credential)
        case let .failure(error):
            continuation?.resume(throwing: error)
        }
        continuation = nil
        controller = nil
    }
}

extension AppleLoginProvider: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authorizationCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
        else {
            finish(with: .failure(AuthError.unexpected))
            return
        }
        finish(with: .success(.apple(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: credential.fullName.flatMap(Self.displayName)
        )))
    }

    /// `PersonNameComponents` → 한 줄 표시 이름. 로캘 규칙을 타므로 직접 잇지 않고 포매터에 맡긴다
    /// (한국어 «서정원», 영어 «Jeongwon Seo»). 구성요소가 다 비면 빈 문자열이 나오므로 nil 로 되돌린다.
    private static func displayName(from components: PersonNameComponents) -> String? {
        let formatted = PersonNameComponentsFormatter
            .localizedString(from: components, style: .default)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return formatted.isEmpty ? nil : formatted
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(with: .failure(Self.mapAppleError(error)))
    }
}

extension AppleLoginProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

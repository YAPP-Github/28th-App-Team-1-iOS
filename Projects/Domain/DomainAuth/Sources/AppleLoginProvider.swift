//
//  AppleLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/12.
//

import AuthenticationServices
import DomainAuthInterface
import UIKit

/// 애플 로그인 연동. ASAuthorization 타입은 이 파일 밖으로 나가지 않는다.
///
/// 클래스 전체를 메인 액터에 격리한다 — `performRequests()`가 시스템 로그인 시트를
/// 제시하는 main-thread-only UI API라 `.run`(cooperative thread pool)에서 직접
/// 호출하면 안 된다(KakaoLoginProvider와 동일 근거). delegate 콜백도 메인 스레드로
/// 도착하므로(애플 샘플 코드가 콜백에서 UI를 직접 갱신) 격리와 정합한다.
@MainActor
final class AppleLoginProvider: NSObject, SocialLoginProvider {
    /// resume 후 nil 정리 — 이중 resume 방지.
    private var continuation: CheckedContinuation<SocialCredential, Error>?
    /// flow 동안 강한 참조 유지 — delegate는 weak라 지역변수로 두면 콜백 전에 해제된다.
    private var controller: ASAuthorizationController?

    func performLogin() async throws -> SocialCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            // name/email 스코프는 요청하지 않는다(YAGNI) — 이 슬라이스엔 소비자가 없고
            // 최초 승인에만 오는 값이지만 출시 전이라 revoke 후 재승인으로 재획득 가능.
            // 백엔드 수신 필드 확정 시 스코프+payload를 함께 확장한다.
            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    /// 취소만 구분하고 나머지는 .unexpected — State가 다르게 반응해야 하는 경우의 수만 유지.
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
            authorizationCode: authorizationCode
        )))
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
        // 미지정 시 멀티 씬 등에서 제시 실패 가능 — key window를 명시적으로 반환한다.
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

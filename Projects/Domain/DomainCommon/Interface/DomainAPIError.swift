//
//  DomainAPIError.swift
//  DomainCommonInterface
//
//  Created by EunseoKim on 26/07/25.
//

import ComposableArchitecture
import CoreNetworkInterface

// @lat: [[api#공통 규약]]
/// 도메인 API 에러 공통 계약 — 인프라 에러(ServerError·NetworkError·NotAuthenticatedError)를
/// 도메인 에러로 좁히는 규칙을 한 곳에 둔다. 각 도메인은 고유 서버 코드 매핑(`init?(serverCode:message:)`)만 구현.
/// 케이스 설계는 기존 원칙 그대로("State 가 다르게 반응해야 하는 경우의 수만큼만") — 이 계약은 매핑만 공통화한다.
/// 서버 코드 ↔ 케이스 표는 [[api]] 도메인별 섹션.
public protocol DomainAPIError: Error {
    /// 재로그인 필요 — LOGIN_EXPIRED·TOKEN_EXPIRED·INVALID_TOKEN 및 NotAuthenticatedError 공통 매핑.
    /// 무인증 API 도메인은 도달하지 않는 경로 — `unexpected` 별칭으로 충족한다.
    static var sessionExpired: Self { get }
    /// URLSession transport 실패 — 오프라인·타임아웃
    static var networkFailure: Self { get }
    /// 5xx — 서버 장애
    static var serverUnavailable: Self { get }
    static var unexpected: Self { get }

    /// 도메인 고유 서버 코드 → 케이스. 모르는 코드는 nil — 공통 폴백(5xx → serverUnavailable, 그 외 `fallback`)으로 넘어간다.
    init?(serverCode code: String, message: String)

    /// 어떤 케이스로도 승격되지 않은 4xx 서버 에러의 폴백. 기본 `unexpected` —
    /// 미승격 에러를 화면까지 흘려야 하는 도메인(`server(...)` 케이스 패턴)만 재정의한다.
    /// ServerError 를 통째로 받는다 — 임시 노출 규칙(«CODE(status)» Alert)에 statusCode 까지 필요해서.
    static func fallback(unrecognized error: ServerError) -> Self

    /// 미승격 서버 에러 원문 — `server(...)` 케이스에 담긴 값. 승격된 에러는 nil.
    /// 기본 nil 이라 `fallback` 을 재정의하지 않은 도메인은 구현할 것이 없다.
    var unrecognizedServerError: ServerError? { get }
}

public extension DomainAPIError {
    static func fallback(unrecognized error: ServerError) -> Self {
        .unexpected
    }

    var unrecognizedServerError: ServerError? { nil }

    /// 미승격 서버 에러코드의 기본 Alert — 임시 노출 규칙(2026-08-02, [[api#공통 규약]]):
    /// title «CODE(status)»(Spring 포맷은 상태코드), message 는 서버 원문.
    /// 도메인이 케이스로 승격한 에러는 nil 이다 — 그건 화면이 자기 문구로 처리한다.
    /// Feature 마다 같은 Alert 를 조립하지 않도록 여기 한 곳에 둔다 (CoreNetwork 타입도 새지 않는다).
    func serverAlertState<Action>() -> AlertState<Action>? {
        guard let error = unrecognizedServerError else { return nil }
        return AlertState(
            title: { TextState(error.alertTitle) },
            actions: { ButtonState(role: .cancel) { TextState("확인") } },
            message: { TextState(error.alertMessage) }
        )
    }

    /// 인프라 에러를 도메인 에러로 좁혀 다시 던진다.
    /// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
    static func mapping<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw Self(mapping: error)
        }
    }

    init(mapping error: any Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as ServerError:
            self.init(serverError: error)
        case is NotAuthenticatedError:
            self = .sessionExpired
        case let error as NetworkError:
            self.init(networkError: error)
        default:
            self = .unexpected
        }
    }
}

private extension DomainAPIError {
    init(serverError error: ServerError) {
        switch error.code {
        case "LOGIN_EXPIRED", "TOKEN_EXPIRED", "INVALID_TOKEN":
            self = .sessionExpired
        default:
            if let domainCase = Self(serverCode: error.code, message: error.message) {
                self = domainCase
            } else if error.statusCode >= 500 {
                self = .serverUnavailable
            } else {
                self = Self.fallback(unrecognized: error)
            }
        }
    }

    init(networkError error: NetworkError) {
        switch error {
        case .transport:
            self = .networkFailure
        case .statusCode(let status, _) where status >= 500:
            self = .serverUnavailable
        default:
            // .invalidBaseURL·.invalidURL·.invalidResponse, 또는 envelope 이 아닌 4xx body
            self = .unexpected
        }
    }
}

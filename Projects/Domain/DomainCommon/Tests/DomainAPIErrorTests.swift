//
//  DomainAPIErrorTests.swift
//  DomainCommonTests
//
//  Created by EunseoKim on 26/07/25.
//

import CoreNetworkInterface
import DomainCommonInterface
import Foundation
import Testing

/// DomainAPIError 공통 매핑 규칙 검증 — 도메인별 고유 코드 매핑은 각 도메인 ClientLive 테스트가 맡고,
/// 여기서는 모든 도메인이 물려받는 공통 경로(토큰 만료·5xx·transport·폴백·취소 통과)만 본다.
private enum StubError: DomainAPIError, Equatable {
    case known
    case invalid(message: String)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected

    init?(serverCode code: String, message: String) {
        switch code {
        case "KNOWN": self = .known
        case "VALIDATION": self = .invalid(message: message)
        default: return nil
        }
    }
}

/// fallback 재정의 검증용 (Interview 의 `server(code:message:)` 패턴).
private enum FallbackStubError: DomainAPIError, Equatable {
    case server(code: String, message: String)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected

    init?(serverCode code: String, message: String) { nil }

    static func fallback(unrecognizedCode code: String, message: String) -> FallbackStubError {
        .server(code: code, message: message)
    }
}

struct DomainAPIErrorTests {
    @Test("도메인이 아는 서버 코드는 고유 케이스로 매핑한다")
    func knownServerCode() {
        let error = StubError(mapping: ServerError(code: "KNOWN", message: "m", statusCode: 400))
        #expect(error == .known)
        let validation = StubError(mapping: ServerError(code: "VALIDATION", message: "문구", statusCode: 400))
        #expect(validation == .invalid(message: "문구"))
    }

    @Test("토큰 만료 3코드는 도메인 매핑보다 먼저 sessionExpired 로 승격한다", arguments: ["LOGIN_EXPIRED", "TOKEN_EXPIRED", "INVALID_TOKEN"])
    func tokenCodes(code: String) {
        let error = StubError(mapping: ServerError(code: code, message: "m", statusCode: 401))
        #expect(error == .sessionExpired)
    }

    @Test("NotAuthenticatedError 는 sessionExpired 로 매핑한다")
    func notAuthenticated() {
        #expect(StubError(mapping: NotAuthenticatedError()) == .sessionExpired)
    }

    @Test("미인식 서버 코드 — 5xx 는 serverUnavailable, 4xx 는 기본 폴백 unexpected")
    func unrecognizedServerCode() {
        #expect(StubError(mapping: ServerError(code: "NEW_CODE", message: "m", statusCode: 500)) == .serverUnavailable)
        #expect(StubError(mapping: ServerError(code: "NEW_CODE", message: "m", statusCode: 409)) == .unexpected)
    }

    @Test("미인식 4xx 폴백은 도메인이 재정의할 수 있다 (Interview 의 server 케이스 패턴)")
    func fallbackOverride() {
        let error = FallbackStubError(mapping: ServerError(code: "NEW_CODE", message: "원문", statusCode: 409))
        #expect(error == .server(code: "NEW_CODE", message: "원문"))
        // 5xx 는 재정의와 무관하게 공통 규칙 우선
        #expect(FallbackStubError(mapping: ServerError(code: "NEW_CODE", message: "m", statusCode: 503)) == .serverUnavailable)
    }

    @Test("NetworkError — transport 는 networkFailure, 5xx 는 serverUnavailable, envelope 아닌 4xx 는 unexpected")
    func networkErrors() {
        #expect(StubError(mapping: NetworkError.transport(.notConnectedToInternet)) == .networkFailure)
        #expect(StubError(mapping: NetworkError.statusCode(502, Data())) == .serverUnavailable)
        #expect(StubError(mapping: NetworkError.statusCode(404, Data())) == .unexpected)
        #expect(StubError(mapping: NetworkError.invalidResponse) == .unexpected)
    }

    @Test("이미 도메인 에러면 그대로 통과한다")
    func passthroughDomainError() {
        #expect(StubError(mapping: StubError.known) == .known)
    }

    @Test("mapping 래퍼 — 취소는 도메인 에러로 삼키지 않고 CancellationError 그대로 던진다")
    func cancellationPassesThrough() async {
        do {
            _ = try await StubError.mapping { throw CancellationError() }
            Issue.record("에러가 던져져야 한다")
        } catch is CancellationError {
            // 통과 — 실패가 아니므로 도메인 에러로 매핑되지 않는다
        } catch {
            Issue.record("CancellationError 가 아니라 \(error)")
        }
    }

    @Test("mapping 래퍼 — 인프라 에러를 도메인 에러로 좁혀 던진다")
    func mappingWrapsInfraError() async {
        do {
            _ = try await StubError.mapping { throw ServerError(code: "KNOWN", message: "m", statusCode: 400) }
            Issue.record("에러가 던져져야 한다")
        } catch let error as StubError {
            #expect(error == .known)
        } catch {
            Issue.record("StubError 가 아니라 \(error)")
        }
    }
}

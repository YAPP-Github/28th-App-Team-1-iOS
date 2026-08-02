//
//  ServerEnvelopeTests.swift
//  CoreNetworkTests
//
//  Created by EunseoKim on 26/07/18.
//

import CoreNetworkInterface
import XCTest
@testable import CoreNetworkImplementation

final class ServerEnvelopeTests: XCTestCase {
    private struct Payload: Decodable, Equatable {
        let name: String
    }

    func test_unwrap_성공envelope의_data를_벗긴다() throws {
        let json = Data(#"{"success": true, "data": {"name": "hilit"}}"#.utf8)

        let payload: Payload = try ServerEnvelope.unwrap(from: json)

        XCTAssertEqual(payload, Payload(name: "hilit"))
    }

    func test_unwrap_envelope이_아니면_직접디코드로_폴백한다() throws {
        // Swagger 일부 스키마가 envelope 없이 표기돼 있어(annotation 누락) 방어하는 경로
        let json = Data(#"{"name": "hilit"}"#.utf8)

        let payload: Payload = try ServerEnvelope.unwrap(from: json)

        XCTAssertEqual(payload, Payload(name: "hilit"))
    }

    func test_ServerError_decode_서버에러payload를_읽는다() {
        let body = Data(#"{"success": false, "code": "NO_REMAINING_TICKET", "message": "남은 이용권이 없어요."}"#.utf8)

        let error = ServerError.decode(statusCode: 403, body: body)

        XCTAssertEqual(error, ServerError(code: "NO_REMAINING_TICKET", message: "남은 이용권이 없어요.", statusCode: 403))
    }

    func test_ServerError_decode_Spring기본포맷을_읽는다() {
        // 서버가 코드로 승격하지 않은 에러 (2026-08-02 확인) — code 빈 문자열, message 에 error 원문.
        let body = Data(#"{"timestamp": "2026-08-02T03:33:33.209+00:00", "status": 403, "error": "Forbidden", "path": "/api/v1/consents/pending"}"#.utf8)

        let error = ServerError.decode(statusCode: 403, body: body)

        XCTAssertEqual(error, ServerError(code: "", message: "Forbidden", statusCode: 403))
    }

    func test_ServerError_alert표기_정의코드와_Spring포맷이_다르다() {
        // 임시 노출 규칙(2026-08-02): 정의 코드 «CODE(status)» / Spring 은 상태코드만.
        let defined = ServerError(code: "INVALID_CONSENT_ITEM", message: "지원하지 않는 동의 항목이에요.", statusCode: 400)
        XCTAssertEqual(defined.alertTitle, "INVALID_CONSENT_ITEM(400)")
        XCTAssertEqual(defined.alertMessage, "지원하지 않는 동의 항목이에요.")

        let spring = ServerError(code: "", message: "Forbidden", statusCode: 403)
        XCTAssertEqual(spring.alertTitle, "403")
        XCTAssertEqual(spring.alertMessage, "Forbidden")
    }

    func test_ServerError_decode_두_포맷_다_아니면_nil() {
        XCTAssertNil(ServerError.decode(statusCode: 500, body: Data("Internal Server Error".utf8)))
    }

    func test_JSONDecoder_api_LocalDateTime과_ISO8601을_모두_디코딩한다() throws {
        struct Timestamps: Decodable {
            let local: Date
            let iso: Date
        }
        let json = Data(#"{"local": "2026-07-06T10:00:04", "iso": "2026-07-06T01:00:04Z"}"#.utf8)

        let decoded = try JSONDecoder.api.decode(Timestamps.self, from: json)

        // 서버 LocalDateTime 은 KST 가정 — "2026-07-06T10:00:04"(KST) == "2026-07-06T01:00:04Z"(UTC)
        XCTAssertEqual(decoded.local, decoded.iso)
    }
}

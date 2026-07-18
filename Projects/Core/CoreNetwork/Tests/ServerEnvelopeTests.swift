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

    func test_ServerError_decode_envelope이_아니면_nil() {
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

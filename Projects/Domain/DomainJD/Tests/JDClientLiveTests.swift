//
//  JDClientLiveTests.swift
//  DomainJDTests
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainJDInterface
import XCTest
@testable import DomainJDImplementation

final class JDClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> JDClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            JDClient.liveValue
        }
    }

    func test_validate_URL을_보내고_검증실패도_정상흐름으로_디코딩한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/jd/validate")
            XCTAssertEqual(request.method, .post)
            let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: String]
            XCTAssertEqual(body?["jdUrl"], "https://example.com/careers/123")
            // 크롤링 실패는 HTTP 200 + valid=false — 에러가 아니라 폴백 신호다
            return Data("""
            {"success": true, "data": {
                "valid": false, "reason": "CRAWLING_FAILED", "message": "공고 내용을 직접 붙여넣어 주세요."
            }}
            """.utf8)
        }

        let validation = try await client.validate("https://example.com/careers/123")

        XCTAssertFalse(validation.valid)
        XCTAssertEqual(validation.reason, "CRAWLING_FAILED")
    }

    func test_validate_일일한도429를_dailyLimitExceeded로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(429, Data(
                #"{"success": false, "code": "JD_VALIDATION_LIMIT_EXCEEDED", "message": "공고 링크는 하루에 5번까지만 입력할 수 있어요"}"#.utf8
            ))
        }

        do {
            _ = try await client.validate("https://example.com/careers/123")
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? JDError, .dailyLimitExceeded)
        }
    }
}

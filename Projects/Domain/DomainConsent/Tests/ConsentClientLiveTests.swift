//
//  ConsentClientLiveTests.swift
//  DomainConsentTests
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainConsentInterface
import XCTest
@testable import DomainConsentImplementation

final class ConsentClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> ConsentClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            ConsentClient.liveValue
        }
    }

    func test_pending_envelope을_벗겨_consentStatus와_items를_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "consentStatus": "STALE",
            "profileRegistered": true,
            "items": [
                {"code": "TERMS_OF_SERVICE", "label": "서비스 이용약관", "required": true, "version": 2, "hasDocument": true}
            ]
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/consents/pending")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let pending = try await client.pending()

        XCTAssertEqual(pending.status, .stale)
        XCTAssertTrue(pending.profileRegistered)
        XCTAssertEqual(pending.items, [
            ConsentItem(code: "TERMS_OF_SERVICE", label: "서비스 이용약관", isRequired: true, version: 2, hasDocument: true)
        ])
    }

    /// 과도기 폴백 — `profileRegistered`·`items` 가 없어도 판정이 실패하지 않아야 한다(스플래시 갇힘 방지).
    func test_pending_옵셔널_필드가_없으면_미등록과_빈_목록으로_읽는다() async throws {
        let client = makeClient { _ in
            Data(#"{"success": true, "data": {"consentStatus": "UP_TO_DATE"}}"#.utf8)
        }

        let pending = try await client.pending()

        XCTAssertEqual(pending.status, .upToDate)
        XCTAssertFalse(pending.profileRegistered)
        XCTAssertEqual(pending.items, [])
    }

    func test_document_경로에_항목과_버전을_싣는다() async throws {
        let json = """
        {"success": true, "data": {
            "item": "TERMS_OF_SERVICE", "version": 2, "title": "서비스 이용약관", "content": "제1조"
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/consents/TERMS_OF_SERVICE/versions/2")
            return Data(json.utf8)
        }

        let document = try await client.document("TERMS_OF_SERVICE", 2)

        XCTAssertEqual(document.title, "서비스 이용약관")
        XCTAssertEqual(document.content, "제1조")
    }

    func test_submit_items를_body에_싣고_버전불일치400을_versionMismatch로_매핑한다() async throws {
        let submitted = LockIsolated<Data?>(nil)
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/consents")
            XCTAssertEqual(request.method, .post)
            submitted.setValue(request.body)
            throw NetworkError.statusCode(400, Data(
                #"{"success": false, "code": "CONSENT_VERSION_MISMATCH", "message": "동의 항목 버전이 최신이 아니에요."}"#.utf8
            ))
        }

        do {
            try await client.submit([ConsentSubmission(item: "TERMS_OF_SERVICE", version: 1, agreed: true)])
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? ConsentError, .versionMismatch)
        }

        let body = try XCTUnwrap(submitted.value)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: [[String: Any]]]
        let item = try XCTUnwrap(decoded?["items"]?.first)
        XCTAssertEqual(item["item"] as? String, "TERMS_OF_SERVICE")
        XCTAssertEqual(item["version"] as? Int, 1)
        XCTAssertEqual(item["agreed"] as? Bool, true)
    }
}

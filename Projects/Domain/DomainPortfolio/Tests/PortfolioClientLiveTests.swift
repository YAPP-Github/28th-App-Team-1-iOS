//
//  PortfolioClientLiveTests.swift
//  DomainPortfolioTests
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainPortfolioInterface
import XCTest
@testable import DomainPortfolioImplementation

final class PortfolioClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> PortfolioClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            PortfolioClient.liveValue
        }
    }

    func test_list_envelope을_벗겨_목록과_uploadedAt을_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {"portfolios": [{
            "portfolioId": "3E1A8E4B-6C1B-4E1F-9B5A-2F1C0D9E8A70",
            "fileName": "portfolio.pdf",
            "fileSize": 1048576,
            "pageCount": 12,
            "status": "READY",
            "uploadedAt": "2026-07-06T10:00:04"
        }]}}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/portfolios")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let portfolios = try await client.list()

        XCTAssertEqual(portfolios.count, 1)
        XCTAssertEqual(portfolios.first?.status, .ready)
        XCTAssertNotNil(portfolios.first?.uploadedAt)  // LocalDateTime 도 JSONDecoder.api 가 파싱
    }

    func test_register_메타데이터는_query로_PDF는_multipart로_보낸다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/portfolios")
            XCTAssertEqual(request.method, .post)
            let query = Dictionary(uniqueKeysWithValues: request.queryItems.map { ($0.name, $0.value) })
            XCTAssertEqual(query["fileName"], "portfolio.pdf")
            XCTAssertEqual(query["contentType"], "application/pdf")
            XCTAssertEqual(query["fileSize"], "1048576")
            let body = String(bytes: request.body ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains(#"name="file"; filename="portfolio.pdf""#))
            return Data("""
            {"success": true, "data": {
                "portfolioId": "3E1A8E4B-6C1B-4E1F-9B5A-2F1C0D9E8A70", "status": "PROCESSING", "message": "분석을 시작했어요"
            }}
            """.utf8)
        }

        let processing = try await client.register(PortfolioUpload(
            fileName: "portfolio.pdf",
            fileSize: 1_048_576,
            data: Data("pdf-bytes".utf8)
        ))

        XCTAssertEqual(processing.status, .processing)
    }

    func test_register_기등록409를_alreadyExists로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "PORTFOLIO_ALREADY_EXISTS", "message": "이미 등록된 포트폴리오가 있어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.register(PortfolioUpload(fileName: "p.pdf", data: Data()))
            XCTFail("에러가 던져져야 한다")
        } catch {
            // 서버 문구를 배너에 그대로 싣기 때문에 message 까지 보존돼야 한다.
            XCTAssertEqual(error as? PortfolioError, .alreadyExists(message: "이미 등록된 포트폴리오가 있어요."))
        }
    }

    func test_delete_경로에_UUID를_싣는다() async throws {
        let id = UUID(uuidString: "3E1A8E4B-6C1B-4E1F-9B5A-2F1C0D9E8A70")!
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/portfolios/\(id.uuidString)")
            XCTAssertEqual(request.method, .delete)
            return Data("""
            {"success": true, "data": {
                "portfolioId": "3E1A8E4B-6C1B-4E1F-9B5A-2F1C0D9E8A70", "deletedAt": "2026-07-06T10:00:04"
            }}
            """.utf8)
        }

        let deletion = try await client.delete(id)

        XCTAssertEqual(deletion.portfolioId, id)
    }
}

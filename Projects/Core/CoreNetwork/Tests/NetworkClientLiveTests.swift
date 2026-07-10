//
//  NetworkClientLiveTests.swift
//  CoreNetworkTests
//
//  Created by EunseoKim on 26/07/10.
//

import CoreNetworkInterface
import Foundation
import XCTest
@testable import CoreNetworkImplementation

/// `live(session:baseURL:)` 의 응답 처리 계약(2xx 가드·에러 정규화)을 스텁 세션으로 검증한다.
final class NetworkClientLiveTests: XCTestCase {
    private var client: NetworkClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        client = NetworkClient.live(
            session: URLSession(configuration: configuration),
            baseURL: { URL(string: "https://dev-api.architecture.com")! }
        )
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func test_2xx_응답body를_돌려준다() async throws {
        let body = Data(#"[{"id": "interview-1"}]"#.utf8)
        StubURLProtocol.handler = { request in
            (Self.httpResponse(for: request, statusCode: 200), body)
        }

        let data = try await client.request(NetworkRequest(path: "/interviews"))

        XCTAssertEqual(data, body)
    }

    func test_non2xx_statusCode에러에_응답body를_실어_던진다() async {
        let errorBody = Data(#"{"code": "SESSION_EXPIRED"}"#.utf8)
        StubURLProtocol.handler = { request in
            (Self.httpResponse(for: request, statusCode: 401), errorBody)
        }

        do {
            _ = try await client.request(NetworkRequest(path: "/interviews"))
            XCTFail("statusCode 에러가 나야 한다")
        } catch {
            XCTAssertEqual(error as? NetworkError, .statusCode(401, errorBody))
        }
    }

    func test_transport실패_URLError를_NetworkError로_정규화한다() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await client.request(NetworkRequest(path: "/interviews"))
            XCTFail("transport 에러가 나야 한다")
        } catch {
            XCTAssertEqual(error as? NetworkError, .transport(.notConnectedToInternet))
        }
    }

    func test_HTTP응답이_아니면_invalidResponse를_던진다() async {
        StubURLProtocol.handler = { request in
            let nonHTTP = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (nonHTTP, Data())
        }

        do {
            _ = try await client.request(NetworkRequest(path: "/interviews"))
            XCTFail("invalidResponse 에러가 나야 한다")
        } catch {
            XCTAssertEqual(error as? NetworkError, .invalidResponse)
        }
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> URLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

/// 네트워크를 타지 않고 응답/에러를 스텁하는 URLProtocol — 이 테스트 파일 전용.
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (URLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            preconditionFailure("StubURLProtocol.handler 미설정")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

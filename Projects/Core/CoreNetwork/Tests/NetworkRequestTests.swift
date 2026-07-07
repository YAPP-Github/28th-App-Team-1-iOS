//
//  NetworkRequestTests.swift
//  CoreNetworkTests
//
//  Created by EunseoKim on 26/07/07.
//

import CoreNetworkInterface
import XCTest
@testable import CoreNetworkImplementation

final class NetworkRequestTests: XCTestCase {
    private let baseURL = URL(string: "https://dev-api.architecture.com")!

    func test_urlRequest_path와Query를_baseURL에_조합한다() throws {
        let request = NetworkRequest(
            path: "/interviews",
            queryItems: [URLQueryItem(name: "page", value: "1")]
        )

        let urlRequest = try request.urlRequest(baseURL: baseURL)

        XCTAssertEqual(
            urlRequest.url?.absoluteString,
            "https://dev-api.architecture.com/interviews?page=1"
        )
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    func test_urlRequest_method와_header와_body를_반영한다() throws {
        let body = Data("{}".utf8)
        let request = NetworkRequest(
            method: .post,
            path: "/interviews",
            headers: ["Content-Type": "application/json"],
            body: body
        )

        let urlRequest = try request.urlRequest(baseURL: baseURL)

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.httpBody, body)
    }

    func test_request_as_응답을_Decodable로_디코딩한다() async throws {
        struct Payload: Codable, Equatable {
            let id: Int
        }
        let client = NetworkClient(request: { _ in try JSONEncoder().encode(Payload(id: 7)) })

        let decoded = try await client.request(NetworkRequest(path: "/x"), as: Payload.self)

        XCTAssertEqual(decoded, Payload(id: 7))
    }
}

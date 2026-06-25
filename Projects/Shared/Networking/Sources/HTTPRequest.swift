//
//  HTTPRequest.swift
//  Networking
//

import Foundation

/// HTTP 메서드.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// 한 번의 HTTP 요청 명세.
///
/// `baseURL` 은 포함하지 않는다 — 호출 측(`*ClientLive`)이 `@Dependency(\.appConfig)` 의
/// 환경별 baseURL 을 주입한다. 즉 ``Networking`` 은 어느 서버를 치는지 모른다.
public struct HTTPRequest: Sendable {
    public var method: HTTPMethod
    /// baseURL 에 append 되는 경로. 예: `"users"`, `"users/3"`.
    public var path: String
    public var query: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        method: HTTPMethod = .get,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }
}

/// transport 계층 에러. 도메인 의미(예: notFound)는 각 `*ClientLive` 가 매핑한다.
public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    /// HTTPURLResponse 가 아닌 응답.
    case invalidResponse
    /// 2xx 가 아닌 상태코드 + 원본 바디.
    case status(code: Int, data: Data)
    /// URLSession 레벨 실패(연결 끊김·타임아웃 등).
    case transport(String)
    /// 디코딩 실패.
    case decoding(String)
}

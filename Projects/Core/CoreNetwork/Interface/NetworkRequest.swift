//
//  NetworkRequest.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/07.
//

import Foundation

/// baseURL 을 모르는 상대 경로 요청 명세.
/// baseURL 해석은 Implementation(liveValue) 책임 — 환경(xcconfig `API_BASE_URL`)마다
/// 달라지는 값이라 계약에 두지 않는다.
public struct NetworkRequest: Equatable, Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public var method: Method
    public var path: String
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        method: Method = .get,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

public extension NetworkRequest {
    /// Encodable body 를 JSON 으로 인코딩하고 `Content-Type: application/json` 을 세팅한 요청.
    /// 응답 쪽 `NetworkClient.request(_:as:)` 와 대칭. 인코딩 실패는 `EncodingError` 그대로 던진다.
    static func json(
        method: Method,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: some Encodable,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> NetworkRequest {
        var headers = headers
        headers["Content-Type"] = "application/json"
        return NetworkRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            headers: headers,
            body: try encoder.encode(body)
        )
    }
}

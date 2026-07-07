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

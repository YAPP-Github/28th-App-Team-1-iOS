//
//  NetworkClientLive.swift
//  CoreNetworkImplementation
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreNetworkInterface
import Foundation

extension NetworkClient: DependencyKey {
    /// URLSession 기반 실제 구현. Implementation 은 App/Example 만 link 한다 (D4).
    public static var liveValue: NetworkClient {
        live(session: .shared)
    }

    /// 세션·baseURL 을 주입할 수 있는 팩토리 — Tests 가 스텁 세션/baseURL 로 검증한다.
    public static func live(
        session: URLSession,
        baseURL: @escaping @Sendable () throws -> URL = defaultBaseURL
    ) -> NetworkClient {
        NetworkClient(
            request: { request in
                let urlRequest = try request.urlRequest(baseURL: baseURL())
                let data: Data
                let response: URLResponse
                do {
                    (data, response) = try await session.data(for: urlRequest)
                } catch let error as URLError where error.code == .cancelled {
                    // 구조적 동시성 취소는 실패가 아니다 — TCA `.run` 이 조용히 무시하도록 취소로 전파
                    throw CancellationError()
                } catch let error as URLError {
                    throw NetworkError.transport(error.code)
                }
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw NetworkError.statusCode(http.statusCode, data)
                }
                return data
            }
        )
    }

    /// 계별 xcconfig(Dev/QA/Prod) → Info.plist 로 치환된 `API_BASE_URL`. → DocC Environments
    public static func defaultBaseURL() throws -> URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: raw) else {
            throw NetworkError.invalidBaseURL
        }
        return url
    }
}

extension NetworkRequest {
    /// 상대 path + query 를 baseURL 에 얹어 URLRequest 로 변환한다.
    func urlRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        for (field, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }
}

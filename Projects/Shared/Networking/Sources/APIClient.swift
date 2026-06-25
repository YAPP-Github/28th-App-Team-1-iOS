//
//  APIClient.swift
//  Networking
//

import ComposableArchitecture
import Foundation

/// 순정 `URLSession` 기반 HTTP transport.
///
/// 라이브러리 의존 없이 `URLSession` 의 async API 만 얇게 감쌌다. 의존성 seam 은
/// 단 하나(``data``) 라서 테스트에서 바이트 수준으로 자유롭게 stub 할 수 있다.
///
/// `*ClientLive` 에서의 사용 예:
/// ```swift
/// extension UserClient: DependencyKey {
///     public static var liveValue: UserClient {
///         @Dependency(\.appConfig) var config
///         @Dependency(\.apiClient) var api
///         return UserClient(
///             fetchUsers: {
///                 try await api.decoded([User].self, baseURL: config.baseURL, .init(path: "users"))
///             },
///             fetchUser: { id in
///                 try await api.decoded(User.self, baseURL: config.baseURL, .init(path: "users/\(id)"))
///             }
///         )
///     }
/// }
/// ```
// @lat: [[clients#공유 transport]]
public struct APIClient: Sendable {
    /// 원본 바이트만 책임진다. baseURL·도메인 무지 → 전 Client 가 공유하는 순수 transport.
    public var data: @Sendable (_ baseURL: URL, _ request: HTTPRequest) async throws -> Data

    public init(data: @escaping @Sendable (URL, HTTPRequest) async throws -> Data) {
        self.data = data
    }
}

public extension APIClient {
    /// 요청을 보내고 응답 바디를 `Decodable` 로 디코딩한다.
    func decoded<Value: Decodable>(
        _ type: Value.Type = Value.self,
        baseURL: URL,
        _ request: HTTPRequest,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Value {
        let raw = try await data(baseURL, request)
        do {
            return try decoder.decode(Value.self, from: raw)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}

public extension APIClient {
    /// 실제 `URLSession` 구현. baseURL+path+query 로 URL 을 만들고 2xx 만 통과시킨다.
    static func live(session: URLSession = .shared) -> APIClient {
        APIClient(data: { baseURL, request in
            guard var components = URLComponents(
                url: baseURL.appendingPathComponent(request.path),
                resolvingAgainstBaseURL: false
            ) else {
                throw APIError.invalidURL
            }
            if !request.query.isEmpty {
                components.queryItems = request.query
            }
            guard let url = components.url else {
                throw APIError.invalidURL
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.rawValue
            urlRequest.httpBody = request.body
            for (field, value) in request.headers {
                urlRequest.setValue(value, forHTTPHeaderField: field)
            }

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: urlRequest)
            } catch {
                throw APIError.transport(String(describing: error))
            }

            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                throw APIError.status(code: http.statusCode, data: data)
            }
            return data
        })
    }
}

extension APIClient: DependencyKey {
    public static let liveValue = APIClient.live()

    /// 테스트는 명시 주입을 강제 — 미주입 호출은 즉시 실패한다.
    public static let testValue = APIClient(
        data: unimplemented("APIClient.data", placeholder: Data())
    )
}

public extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

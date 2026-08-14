//
//  NetworkClientLive.swift
//  CoreNetworkImplementation
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreCommonInterface
import CoreNetworkInterface
import Foundation

extension NetworkClient: DependencyKey {
    /// URLSession 기반 실제 구현. Implementation 은 App/Example 만 link 한다 (D4).
    /// `trackingActivity()` — 전 API in-flight 를 `NetworkActivity` 에 반영 (전역 로딩 신호).
    public static var liveValue: NetworkClient {
        live(session: .shared).trackingActivity()
    }

    /// 세션·baseURL 을 주입할 수 있는 팩토리 — Tests 가 스텁 세션/baseURL 로 검증한다.
    public static func live(
        session: URLSession,
        baseURL: @escaping @Sendable () throws -> URL = defaultBaseURL
    ) -> NetworkClient {
        NetworkClient(
            request: { request in
                let urlRequest = try request.urlRequest(baseURL: baseURL())
                if LogGate.isVerbose {
                    NetworkLogger.request(urlRequest)
                }
                let data: Data
                let response: URLResponse
                do {
                    (data, response) = try await session.data(for: urlRequest)
                } catch let error as URLError where error.code == .cancelled {
                    // 구조적 동시성 취소는 실패가 아니다 — TCA `.run` 이 조용히 무시하도록 취소로 전파
                    throw CancellationError()
                } catch let error as URLError {
                    if LogGate.isVerbose {
                        NetworkLogger.failure("transport \(error.code.rawValue)", url: urlRequest.url?.absoluteString ?? "")
                    }
                    throw NetworkError.transport(error.code)
                }
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                if LogGate.isVerbose {
                    NetworkLogger.response(http, data: data, url: urlRequest.url?.absoluteString ?? "")
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

/// 네트워크 로깅. 모든 실 HTTP 가 `NetworkClient.live` 한 곳을 지나므로 요청/응답이 전부 찍힌다.
/// 모든 구성에 컴파일되고 노출 여부는 런타임 `LogGate.isVerbose` 가 정한다 — QA(release 구성)에서도 보인다.
enum NetworkLogger {
    static func request(_ req: URLRequest) {
        print("🌐 [REQ] \(req.httpMethod ?? "?") \(req.url?.absoluteString ?? "?")")
        if let headers = req.allHTTPHeaderFields, !headers.isEmpty {
            print("   headers: \(headers)")
        }
        if let body = req.httpBody, !body.isEmpty {
            print("   body: \(String(decoding: body, as: UTF8.self))")
        }
    }

    static func response(_ http: HTTPURLResponse, data: Data, url: String) {
        let icon = (200..<300).contains(http.statusCode) ? "✅" : "❌"
        print("\(icon) [RES] \(http.statusCode) \(url)")
        if !data.isEmpty {
            print("   body: \(String(decoding: data, as: UTF8.self))")
        }
    }

    static func failure(_ message: String, url: String) {
        print("❌ [REQ-FAIL] \(message) \(url)")
    }
}

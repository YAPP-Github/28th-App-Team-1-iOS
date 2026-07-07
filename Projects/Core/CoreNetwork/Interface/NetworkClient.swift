//
//  NetworkClient.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import Foundation

// @lat: [[domain.map#네트워킹 인프라]]
// 모든 외부 HTTP IO 가 거치는 인프라 계약. 소비자는 Domain Implementation 뿐이다 —
// Feature 는 Domain(Client)만 알고 이 모듈의 존재를 모른다.
public struct NetworkClient: Sendable {
    /// 요청을 보내고 응답 body 를 돌려준다. 2xx 밖이면 `NetworkError.statusCode` 를 던진다.
    public var request: @Sendable (NetworkRequest) async throws -> Data

    public init(request: @escaping @Sendable (NetworkRequest) async throws -> Data) {
        self.request = request
    }
}

public extension NetworkClient {
    /// 응답 body 를 Decodable 로 디코딩하는 편의 오버로드.
    func request<Response: Decodable>(
        _ request: NetworkRequest,
        as type: Response.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Response {
        let data = try await self.request(request)
        return try decoder.decode(type, from: data)
    }
}

extension NetworkClient: TestDependencyKey {
    public static var testValue: NetworkClient {
        NetworkClient(
            request: unimplemented("NetworkClient.request", placeholder: Data())
        )
    }
}

public extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClient.self] }
        set { self[NetworkClient.self] = newValue }
    }
}

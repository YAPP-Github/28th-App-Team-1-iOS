//
//  NetworkClientMock.swift
//  CoreNetworkTesting
//
//  Created by EunseoKim on 26/07/07.
//

import CoreNetworkInterface
import Foundation

public extension NetworkClient {
    /// 고정 응답을 돌려주는 mock. 다른 모듈의 테스트·Preview 에서 주입한다.
    static func mock(returning data: Data = Data()) -> NetworkClient {
        NetworkClient(request: { _ in data })
    }

    /// Encodable 값을 JSON 응답으로 돌려주는 mock.
    static func mock(json value: some Encodable & Sendable) -> NetworkClient {
        NetworkClient(request: { _ in try JSONEncoder().encode(value) })
    }

    /// 항상 주어진 에러를 던지는 mock — 에러 경로 테스트·Preview 용.
    static func mock(throwing error: any Error) -> NetworkClient {
        NetworkClient(request: { _ in throw error })
    }
}

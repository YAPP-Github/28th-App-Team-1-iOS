//
//  NetworkError.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/07.
//

import Foundation

public enum NetworkError: Error, Equatable {
    /// Info.plist 의 `API_BASE_URL` 이 없거나 URL 형식이 아님 (xcconfig 미설정)
    case invalidBaseURL
    /// path/query 조합이 URL 로 만들어지지 않음
    case invalidURL
    /// HTTP 응답이 아님
    case invalidResponse
    /// 2xx 밖의 상태 코드
    case statusCode(Int)
}

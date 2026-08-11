//
//  NetworkError.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/07.
//

import Foundation

/// `NetworkClient` 실패의 전체 표면 — Equatable 이라 Reducer/TestStore 에서 그대로 단언한다.
/// 취소만 예외로 `CancellationError` 로 나간다 (실패가 아니므로).
public enum NetworkError: Error, Equatable {
    /// Info.plist 의 `API_BASE_URL` 이 없거나 URL 형식이 아님 (xcconfig 미설정)
    case invalidBaseURL
    /// path/query 조합이 URL 로 만들어지지 않음
    case invalidURL
    /// URLSession transport 실패 — 오프라인(.notConnectedToInternet)·타임아웃(.timedOut) 등
    case transport(URLError.Code)
    /// HTTP 응답이 아님
    case invalidResponse
    /// 2xx 밖의 상태 코드 + 응답 body. body 는 서버 에러 payload — Domain 이 도메인 에러로 매핑할 때 쓴다
    case statusCode(Int, Data)
}

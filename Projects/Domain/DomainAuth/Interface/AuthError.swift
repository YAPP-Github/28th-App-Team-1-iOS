//
//  AuthError.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

/// State가 다르게 반응해야 하는 경우의 수만큼만 둔 에러. 원인 상세는 매핑 함수에서 로깅한다.
public enum AuthError: Error, Equatable, Sendable {
    case cancelled
    case networkFailure
    case invalidCredential
    case serverUnavailable
    case sessionExpired
    case unexpected
}

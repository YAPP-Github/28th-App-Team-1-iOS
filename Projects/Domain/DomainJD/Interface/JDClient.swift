//
//  JDClient.swift
//  DomainJDInterface
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// JD URL 검증 결과. `valid == false` 면 본문 직접 입력(jdText) 폴백이 필수 UX.
public struct JDValidation: Decodable, Equatable, Sendable {
    public let valid: Bool
    /// 실패 사유 코드 — CRAWLING_FAILED · CONTENT_TOO_SHORT · EXTRACTION_FAILED (성공 시 nil)
    public let reason: String?
    /// 사용자 안내 문구 (성공 시 nil)
    public let message: String?

    public init(valid: Bool, reason: String?, message: String?) {
        self.valid = valid
        self.reason = reason
        self.message = message
    }
}

// MARK: - Client

/// JD 크롤링/검증 API (D14 `/api/v1/jd/**`).
/// 검증 성공 시 서버가 정제된 JD 를 캐싱 — 이후 `InterviewClient.createSession` 의 `.url` 입력이 이 캐시를 쓴다.
// @lat: [[api#JD]]
// depends-on: [[api#Interview]] (createSession 의 jdUrl 사전 검증 계약 — JD_NOT_VALIDATED)
public struct JDClient: Sendable {
    /// POST /jd/validate — 크롤링 + AI 정제 + 캐싱. HTTP 200 이어도 `valid` 로 성공 여부를 판단한다.
    public var validate: @Sendable (_ jdURL: String) async throws -> JDValidation

    public init(validate: @escaping @Sendable (_ jdURL: String) async throws -> JDValidation) {
        self.validate = validate
    }
}

extension JDClient: TestDependencyKey {
    public static var testValue: JDClient {
        JDClient(validate: unimplemented("JDClient.validate"))
    }

    public static var previewValue: JDClient {
        JDClient(validate: { _ in JDValidation(valid: true, reason: nil, message: nil) })
    }
}

public extension DependencyValues {
    var jdClient: JDClient {
        get { self[JDClient.self] }
        set { self[JDClient.self] = newValue }
    }
}

//
//  AppVersionClient.swift
//  DomainAppVersionInterface
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 강제/권장 업데이트 판정. 판정 규칙(버전 비교)은 전부 서버 책임 — 클라이언트는 결과만 따른다.
public enum AppVersionUpdateType: String, Decodable, Sendable {
    /// 현재 버전 < 최소 지원 버전 — 업데이트 전까지 앱 진입 차단
    case force = "FORCE"
    /// 최소 지원 ≤ 현재 < 최신 — 권장 안내 (건너뛰기 가능)
    case optional = "OPTIONAL"
    /// 최신 — 안내 없음
    case none = "NONE"
}

/// 앱 버전 정책 조회 응답.
public struct AppVersionPolicy: Decodable, Equatable, Sendable {
    public let updateType: AppVersionUpdateType
    /// 스토어 최신 버전 (예: "1.4.0")
    public let latestVersion: String
    /// 최소 지원 버전 — 이 버전 미만이면 FORCE
    public let minSupportedVersion: String
    /// App Store 링크 — 업데이트 버튼이 여는 URL
    public let storeUrl: String

    public init(
        updateType: AppVersionUpdateType,
        latestVersion: String,
        minSupportedVersion: String,
        storeUrl: String
    ) {
        self.updateType = updateType
        self.latestVersion = latestVersion
        self.minSupportedVersion = minSupportedVersion
        self.storeUrl = storeUrl
    }
}

// MARK: - Client

/// 앱 버전 정책 API (D14 `/api/v1/app-versions/**`) — 스플래시에서 강제/권장 업데이트 판정.
/// 무인증 API (로그인 전 호출).
// @lat: [[api#AppVersion]]
public struct AppVersionClient: Sendable {
    /// GET /app-versions/check — 현재 마케팅 버전(`x.x.x`)을 보내 판정을 받는다. platform 은 IOS 고정.
    public var check: @Sendable (_ version: String) async throws -> AppVersionPolicy

    public init(check: @escaping @Sendable (_ version: String) async throws -> AppVersionPolicy) {
        self.check = check
    }
}

extension AppVersionClient: TestDependencyKey {
    public static var testValue: AppVersionClient {
        AppVersionClient(
            check: unimplemented("AppVersionClient.check")
        )
    }

    public static var previewValue: AppVersionClient {
        AppVersionClient(
            check: { _ in
                AppVersionPolicy(
                    updateType: .none,
                    latestVersion: "1.0.0",
                    minSupportedVersion: "1.0.0",
                    storeUrl: "https://apps.apple.com/app/id000000000"
                )
            }
        )
    }
}

public extension DependencyValues {
    var appVersionClient: AppVersionClient {
        get { self[AppVersionClient.self] }
        set { self[AppVersionClient.self] = newValue }
    }
}

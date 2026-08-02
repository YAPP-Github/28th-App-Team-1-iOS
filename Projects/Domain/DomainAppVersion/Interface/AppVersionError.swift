//
//  AppVersionError.swift
//  DomainAppVersionInterface
//
//  Created by EunseoKim on 26/08/01.
//

import DomainCommonInterface

/// AppVersion API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// 서버 고유 코드(INVALID_PLATFORM 등)는 정상 클라이언트에서 나올 수 없어 케이스로 승격하지 않는다 —
/// 스플래시는 어떤 실패든 fail-open(게이트 없이 진입)이 기본이고, 오프라인 재시도 안내만 구분한다.
/// 무인증 API 라 sessionExpired 계열이 없다. 매핑 표는 [[api#AppVersion]].
public enum AppVersionError: Error, Equatable, Sendable {
    case networkFailure
    case serverUnavailable
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙은 DomainAPIError 가 처리)

extension AppVersionError: DomainAPIError {
    /// 무인증 API — 토큰 만료 경로에 도달하지 않는다. 프로토콜 요구 충족용 별칭.
    public static var sessionExpired: AppVersionError { .unexpected }

    public init?(serverCode code: String, message: String) {
        return nil   // 고유 코드 전부 unexpected 폴백 (위 주석 참조)
    }
}

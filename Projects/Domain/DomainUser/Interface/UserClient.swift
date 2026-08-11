//
//  UserClient.swift
//  DomainUserInterface
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 회원 프로필 **읽기 모델** (GET 응답). 온보딩(프로필 등록) 전에는 이름·직무·연차가 없을 수 있다.
/// 프로필 수정값은 이후 새로 생성하는 면접 세션부터 반영된다(과거 세션 스냅샷 불변).
public struct UserProfile: Decodable, Equatable, Sendable {
    /// 회원 고유 식별자
    public let userId: UUID?
    public let name: String?
    /// 이메일 — 소셜 계정에서 미제공 시 nil
    public let email: String?
    /// 소셜 로그인 제공자 — "KAKAO" / "APPLE"
    public let provider: String?
    /// 서버 직군 Enum 값 (예: "BACKEND") — `JobClient.jobs` 의 `jobRole` 과 같은 계
    public let jobRole: String?
    /// 직군 한글 표시명 (예: "백엔드")
    public let jobRoleLabel: String?
    /// 연차(년 단위)
    public let careerYears: Int?
    /// 잔여 이용권 수 (무료 3회)
    public let remainingTicketCount: Int

    public init(
        userId: UUID?,
        name: String?,
        email: String?,
        provider: String?,
        jobRole: String?,
        jobRoleLabel: String?,
        careerYears: Int?,
        remainingTicketCount: Int
    ) {
        self.userId = userId
        self.name = name
        self.email = email
        self.provider = provider
        self.jobRole = jobRole
        self.jobRoleLabel = jobRoleLabel
        self.careerYears = careerYears
        self.remainingTicketCount = remainingTicketCount
    }
}

/// 프로필 **쓰기 모델** (PATCH 요청) — 읽기(UserProfile)와 분리해 조회 화면과 수정 화면이 서로의
/// 형태에 묶이지 않게 한다. 세 필드 모두 매 호출 필수 — 이름 유지여도 현재 이름을 담아 보낸다.
public struct UserProfileUpdate: Encodable, Equatable, Sendable {
    /// 한글·영문만, 최대 5자 (필수)
    public var name: String
    /// 서버 직군 Enum 값 (필수)
    public var jobRole: String
    /// 연차(년 단위, 0~10, 필수)
    public var careerYears: Int

    public init(name: String, jobRole: String, careerYears: Int) {
        self.name = name
        self.jobRole = jobRole
        self.careerYears = careerYears
    }
}

// MARK: - Client

/// 회원 API (D14 `/api/v1/users/**`) — 프로필 조회/등록·수정, 회원 탈퇴.
/// 조회(profile)와 수정(updateProfile)은 서로 다른 화면(마이페이지 표시 vs 온보딩·프로필 편집)에서
/// 따로 쓰는 전제 — 읽기/쓰기 모델이 분리돼 있고, 화면은 자기가 쓰는 엔드포인트만 호출한다.
// @lat: [[api#User]]
public struct UserClient: Sendable {
    /// GET /users/me/profile — 이름·이메일·제공자·직무·연차·잔여 이용권.
    public var profile: @Sendable () async throws -> UserProfile
    /// PATCH /users/me/profile — 이름·직무·연차 등록/수정 (온보딩 최초 등록과 재수정 공용).
    public var updateProfile: @Sendable (UserProfileUpdate) async throws -> Void
    /// DELETE /users/me — 회원 탈퇴. 성공 시 클라이언트도 토큰을 반드시 삭제해야 한다.
    public var withdraw: @Sendable () async throws -> Void

    public init(
        profile: @escaping @Sendable () async throws -> UserProfile,
        updateProfile: @escaping @Sendable (UserProfileUpdate) async throws -> Void,
        withdraw: @escaping @Sendable () async throws -> Void
    ) {
        self.profile = profile
        self.updateProfile = updateProfile
        self.withdraw = withdraw
    }
}

extension UserClient: TestDependencyKey {
    public static var testValue: UserClient {
        UserClient(
            profile: unimplemented("UserClient.profile"),
            updateProfile: unimplemented("UserClient.updateProfile"),
            withdraw: unimplemented("UserClient.withdraw")
        )
    }

    public static var previewValue: UserClient {
        UserClient(
            profile: {
                UserProfile(
                    userId: UUID(),
                    name: "히릿",
                    email: "hilit@kakao.com",
                    provider: "KAKAO",
                    jobRole: "BACKEND",
                    jobRoleLabel: "백엔드",
                    careerYears: 3,
                    remainingTicketCount: 2
                )
            },
            updateProfile: { _ in },
            withdraw: {}
        )
    }
}

public extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

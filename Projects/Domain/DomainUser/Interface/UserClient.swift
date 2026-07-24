//
//  UserClient.swift
//  DomainUserInterface
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 회원 프로필. 온보딩(이름 등록) 전에는 `name` 이 없을 수 있다.
/// 프로필 수정값은 이후 새로 생성하는 면접 세션부터 반영된다(과거 세션 스냅샷 불변).
public struct UserProfile: Decodable, Equatable, Sendable {
    public let name: String?
    /// 서버 직군 Enum 값 (예: "BACKEND") — `JobClient.jobs` 의 `jobRole` 과 같은 계
    public let jobRole: String?
    /// 직군 한글 표시명 (예: "백엔드")
    public let jobRoleLabel: String?
    /// 연차(년 단위)
    public let careerYears: Int?
    /// 잔여 이용권 수 (무료 3회)
    public let remainingTicketCount: Int

    public init(
        name: String?,
        jobRole: String?,
        jobRoleLabel: String?,
        careerYears: Int?,
        remainingTicketCount: Int
    ) {
        self.name = name
        self.jobRole = jobRole
        self.jobRoleLabel = jobRoleLabel
        self.careerYears = careerYears
        self.remainingTicketCount = remainingTicketCount
    }
}

/// 프로필 수정 입력 — `name` 은 변경할 때만 담는다 (nil 이면 이름 유지).
public struct UserProfileUpdate: Encodable, Equatable, Sendable {
    public var name: String?
    /// 서버 직군 Enum 값 (필수)
    public var jobRole: String
    /// 연차(년 단위, 필수)
    public var careerYears: Int

    public init(name: String? = nil, jobRole: String, careerYears: Int) {
        self.name = name
        self.jobRole = jobRole
        self.careerYears = careerYears
    }
}

// MARK: - Client

/// 회원 프로필 API (D14 `/api/v1/users/**`) — 프로필 조회/수정, 이름 등록/중복 확인.
// @lat: [[api#User]]
public struct UserClient: Sendable {
    /// GET /users/me/profile — 이름·직무·연차·잔여 이용권.
    public var profile: @Sendable () async throws -> UserProfile
    /// PATCH /users/me/profile — 이름(선택)·직무·연차 수정.
    public var updateProfile: @Sendable (UserProfileUpdate) async throws -> Void
    /// PATCH /users/me/name — 이름 등록/변경 (1~20자, 중복 시 `UserError.nameAlreadyTaken`).
    public var registerName: @Sendable (_ name: String) async throws -> Void
    /// GET /users/name/check — 사용 가능하면 true. 본인이 등록한 이름은 충돌로 보지 않는다.
    public var checkName: @Sendable (_ name: String) async throws -> Bool

    public init(
        profile: @escaping @Sendable () async throws -> UserProfile,
        updateProfile: @escaping @Sendable (UserProfileUpdate) async throws -> Void,
        registerName: @escaping @Sendable (_ name: String) async throws -> Void,
        checkName: @escaping @Sendable (_ name: String) async throws -> Bool
    ) {
        self.profile = profile
        self.updateProfile = updateProfile
        self.registerName = registerName
        self.checkName = checkName
    }
}

extension UserClient: TestDependencyKey {
    public static var testValue: UserClient {
        UserClient(
            profile: unimplemented("UserClient.profile"),
            updateProfile: unimplemented("UserClient.updateProfile"),
            registerName: unimplemented("UserClient.registerName"),
            checkName: unimplemented("UserClient.checkName", placeholder: false)
        )
    }

    public static var previewValue: UserClient {
        UserClient(
            profile: {
                UserProfile(
                    name: "히릿",
                    jobRole: "BACKEND",
                    jobRoleLabel: "백엔드",
                    careerYears: 3,
                    remainingTicketCount: 2
                )
            },
            updateProfile: { _ in },
            registerName: { _ in },
            checkName: { _ in true }
        )
    }
}

public extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

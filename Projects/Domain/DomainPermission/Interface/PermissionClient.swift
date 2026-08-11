//
//  PermissionClient.swift
//  DomainPermissionInterface
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture

// @lat: [[interview#권한]]
// 카메라·마이크 권한 — iOS 는 사용 시점 요청(PRD §8, 온보딩 강제 획득은 심사 리젝).
// 소비처: 면접 준비 화면(P0) — docs/work/ai-interview.md §3.
// testValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).

/// 면접에 필요한 미디어 권한 종류.
public enum MediaPermission: Equatable, Sendable {
    case camera
    case microphone
}

/// 시스템 권한 상태 — restricted 는 denied 로 접는다(사용자가 못 푸는 상태여도 앱 대응은 "설정 안내"로 동일).
public enum PermissionStatus: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
}

public struct PermissionClient: Sendable {
    /// 현재 권한 상태 조회 — 시스템 다이얼로그를 띄우지 않는다.
    public var status: @Sendable (MediaPermission) -> PermissionStatus
    /// 권한 요청 — notDetermined 일 때만 시스템 다이얼로그가 뜬다(이미 결정됐으면 그 값 즉시 반환).
    public var request: @Sendable (MediaPermission) async -> Bool
    /// 이 앱의 설정 화면 열기 — 한번 거부된 권한은 앱이 다시 물을 수 없어 설정 유도가 유일한 경로.
    public var openSettings: @Sendable () async -> Void

    public init(
        status: @escaping @Sendable (MediaPermission) -> PermissionStatus,
        request: @escaping @Sendable (MediaPermission) async -> Bool,
        openSettings: @escaping @Sendable () async -> Void
    ) {
        self.status = status
        self.request = request
        self.openSettings = openSettings
    }
}

extension PermissionClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: PermissionClient {
        PermissionClient(
            status: unimplemented("PermissionClient.status", placeholder: .denied),
            request: unimplemented("PermissionClient.request", placeholder: false),
            openSettings: unimplemented("PermissionClient.openSettings")
        )
    }

    /// Preview 용 — 전부 허용으로 취급해 권한 다이얼로그 없이 화면 흐름을 그린다.
    public static var previewValue: PermissionClient {
        PermissionClient(
            status: { _ in .granted },
            request: { _ in true },
            openSettings: {}
        )
    }
}

public extension DependencyValues {
    var permissionClient: PermissionClient {
        get { self[PermissionClient.self] }
        set { self[PermissionClient.self] = newValue }
    }
}

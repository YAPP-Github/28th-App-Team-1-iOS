//
//  PushClient.swift
//  CorePushInterface
//
//  Created by EunseoKim on 26/07/20.
//

import ComposableArchitecture
import Foundation

// @lat: [[domain.map#푸시 인프라]]
/// 푸시(FCM/APNs) 파사드. 권한 요청·APNs 토큰 전달과 FCM 토큰/수신 이벤트 스트림을
/// 하나의 seam 으로 노출한다. Firebase SDK 는 CorePushImplementation(PushCenter)에 격리되고,
/// App(조립점)은 AppDelegate lifecycle 이벤트를 이 seam 에 연결만 한다.
public struct PushClient: Sendable {
    /// 앱 시작 시 1회(AppDelegate didFinishLaunching) — Firebase 초기화 + delegate 연결.
    /// cold-start 알림 탭을 받으려면 didFinishLaunching 리턴 전에 호출돼야 한다.
    /// GoogleService-Info.plist 가 번들에 없으면 경고만 남기고 no-op 으로 동작한다(graceful).
    public var configure: @MainActor @Sendable () -> Void
    /// 알림 권한 요청(alert/badge/sound). granted 면 APNs 원격 알림 등록까지 이어서 수행한다.
    public var requestAuthorization: @Sendable () async throws -> Bool
    /// AppDelegate 의 APNs device token 콜백을 FCM 에 전달한다 — 스위즐링 비활성이라 명시 배선.
    public var registerAPNSToken: @Sendable (Data) -> Void
    /// FCM registration token 발급/갱신 스트림. 백엔드 디바이스 토큰 등록의 입력이 된다.
    public var fcmTokenUpdates: @Sendable () -> AsyncStream<String>
    /// 알림 수신 이벤트 스트림(포그라운드 수신·탭 진입). 단일 소비자(AppFeature) 전제.
    public var events: @Sendable () -> AsyncStream<PushEvent>

    public init(
        configure: @escaping @MainActor @Sendable () -> Void,
        requestAuthorization: @escaping @Sendable () async throws -> Bool,
        registerAPNSToken: @escaping @Sendable (Data) -> Void,
        fcmTokenUpdates: @escaping @Sendable () -> AsyncStream<String>,
        events: @escaping @Sendable () -> AsyncStream<PushEvent>
    ) {
        self.configure = configure
        self.requestAuthorization = requestAuthorization
        self.registerAPNSToken = registerAPNSToken
        self.fcmTokenUpdates = fcmTokenUpdates
        self.events = events
    }
}

extension PushClient: TestDependencyKey {}

public extension DependencyValues {
    var pushClient: PushClient {
        get { self[PushClient.self] }
        set { self[PushClient.self] = newValue }
    }
}

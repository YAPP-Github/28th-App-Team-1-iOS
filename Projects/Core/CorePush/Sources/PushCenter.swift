//
//  PushCenter.swift
//  CorePushImplementation
//
//  Created by EunseoKim on 26/07/20.
//

import CorePushInterface
import FirebaseCore
import FirebaseMessaging
import os
import UIKit
import UserNotifications

/// FCM/APNs 브릿지. delegate 콜백(UNUserNotificationCenter·Messaging)을 AsyncStream 으로
/// 변환해 PushClient 계약 뒤로 숨긴다. delegate 는 앱 수명 내내 살아야 하므로 싱글턴.
///
/// 스트림 continuation 은 init 에서 eager 생성한다 — cold-start 알림 탭(didReceive)이
/// 소비자 구독(AppFeature onAppear)보다 먼저 도착해도 무제한 버퍼에 보존된다.
/// 가변 상태는 isConfigured 하나뿐이고 lock 으로 보호한다 — @unchecked Sendable 의 근거.
final class PushCenter: NSObject, @unchecked Sendable {
    static let shared = PushCenter()

    let tokenStream: AsyncStream<String>
    let eventStream: AsyncStream<PushEvent>

    private let tokenContinuation: AsyncStream<String>.Continuation
    private let eventContinuation: AsyncStream<PushEvent>.Continuation

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CorePush",
        category: "CorePush"
    )

    /// FirebaseApp.configure() 이후에만 true. 미구성 상태의 Messaging.messaging() 접근은
    /// crash 라 모든 SDK 접근이 이 플래그 뒤에 있다 (delegate 콜백은 구성 후에만 도착).
    private let configuredState = OSAllocatedUnfairLock(initialState: false)
    private var isConfigured: Bool {
        get { configuredState.withLock { $0 } }
        set { configuredState.withLock { $0 = newValue } }
    }

    private override init() {
        (tokenStream, tokenContinuation) = AsyncStream.makeStream(of: String.self)
        (eventStream, eventContinuation) = AsyncStream.makeStream(of: PushEvent.self)
        super.init()
    }

    /// Firebase 초기화 + delegate 연결. GoogleService-Info.plist 가 번들에 없으면
    /// 경고만 남기고 비활성 — Firebase 프로젝트 없이도 앱이 정상 동작한다(graceful).
    @MainActor
    func configure() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            logger.warning("GoogleService-Info.plist 가 번들에 없어 푸시(FCM)를 비활성화합니다 — docs/getting-started.md 의 Firebase 섹션 참고")
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        isConfigured = true
    }

    /// 알림 권한 요청 — granted 면 APNs 등록까지. OS 권한이라 Firebase 미구성이어도 동작한다.
    func requestAuthorization() async throws -> Bool {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        if granted {
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        }
        return granted
    }

    func registerAPNSToken(_ deviceToken: Data) {
        guard isConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - MessagingDelegate

extension PushCenter: MessagingDelegate {
    /// FCM registration token 발급/갱신. APNs 토큰 연결 전에도 불릴 수 있다 — 값만 흘린다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        tokenContinuation.yield(fcmToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushCenter: UNUserNotificationCenterDelegate {
    /// 포그라운드 수신 — 표시 정책의 단일 지점(시스템 배너 + 사운드) + 이벤트 방출.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        Messaging.messaging().appDidReceiveMessage(content.userInfo)   // 스위즐링 비활성 — 전달 지표 수동 보고
        eventContinuation.yield(.foregroundReceived(Self.pushNotification(from: content)))
        return [.banner, .sound]
    }

    /// 알림 탭(기본 액션)으로 진입 — 라우팅 이벤트 방출. cold-start(종료 상태 탭) 포함.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let content = response.notification.request.content
        Messaging.messaging().appDidReceiveMessage(content.userInfo)
        eventContinuation.yield(.tapped(Self.pushNotification(from: content)))
    }

    private static func pushNotification(from content: UNNotificationContent) -> PushNotification {
        PushNotification(
            title: content.title.isEmpty ? nil : content.title,
            body: content.body.isEmpty ? nil : content.body,
            data: PushNotification.sanitizedData(from: content.userInfo)
        )
    }
}

//
//  AppDelegate.swift
//  Hilit
//
//  Created by EunseoKim on 26/07/20.
//

import ComposableArchitecture
import CorePushInterface
import os
import UIKit

// @lat: [[app#푸시 배선]]
/// 푸시(APNs) lifecycle 전용 어댑터. FCM 스위즐링을 끈 상태(FirebaseAppDelegateProxyEnabled=NO)라
/// APNs 콜백을 PushClient seam 에 명시적으로 연결한다 — Firebase SDK 는 CorePushImplementation 에 격리.
final class AppDelegate: NSObject, UIApplicationDelegate {
    @Dependency(\.pushClient) var pushClient

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Hilit",
        category: "AppDelegate"
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // cold-start 알림 탭(didReceive)을 놓치지 않으려면 리턴 전에 delegate 연결이 끝나야 한다.
        pushClient.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        pushClient.registerAPNSToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // 시뮬레이터·프로비저닝 미설정 환경에서 정상적으로 도달한다 — 흐름을 막지 않고 기록만.
        logger.warning("APNs 등록 실패: \(error.localizedDescription, privacy: .public)")
    }
}

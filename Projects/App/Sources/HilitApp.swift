//
//  HilitApp.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import Core
import Domain
import Feature
import Shared

import SwiftUI
import ComposableArchitecture

@main
struct HilitApp: App {
    // APNs lifecycle(디바이스 토큰·cold-start 알림 탭)은 UIApplicationDelegate 에만 도착한다 — 어댑터로 연결.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Dependency(\.authClient) var authClient

    init() {
        authClient.configure(AppSecrets.kakaoNativeAppKey)
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
            .onOpenURL { url in
                authClient.handleOpenURL(url)
            }
        }
    }
}

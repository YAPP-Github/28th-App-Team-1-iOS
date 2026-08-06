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
    /// background URLSession wake 수신 — SwiftUI 수명주기에는 이 콜백이 없어 어댑터가 필요하다.
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

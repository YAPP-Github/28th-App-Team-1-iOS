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

    /// onOpenURL 라우팅이 send 할 수 있도록 프로퍼티로 보유 — body 인라인 생성이면 참조할 곳이 없다.
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        authClient.configure(AppSecrets.kakaoNativeAppKey)
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onOpenURL { url in
                    // hilit 스킴(지인 피드백 딥링크)만 AppFeature 로 — 그 외(kakao{KEY}://)는
                    // 카카오 SDK 콜백 현행 유지. 세부 판정(feedback host·토큰)은 파서 몫.
                    if url.scheme == "hilit" {
                        store.send(.deeplinkReceived(url))
                    } else {
                        authClient.handleOpenURL(url)
                    }
                }
        }
    }
}

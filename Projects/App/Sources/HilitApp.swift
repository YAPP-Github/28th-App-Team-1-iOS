//
//  HilitApp.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import Core
import Domain
import DomainFeedbackShareInterface
import Feature
import Shared

import SwiftUI
import ComposableArchitecture

// depends-on: [[deeplink#두 경로]] — onOpenURL 이 설치 상태 경로의 유일한 입구다(deferred 는 AppFeature 가 스트림으로 받는다).
@main
struct HilitApp: App {
    /// background URLSession wake 수신 — SwiftUI 수명주기에는 이 콜백이 없어 어댑터가 필요하다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Dependency(\.authClient) var authClient
    @Dependency(\.deeplinkClient) var deeplinkClient

    /// onOpenURL 라우팅이 send 할 수 있도록 프로퍼티로 보유 — body 인라인 생성이면 참조할 곳이 없다.
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        authClient.configure(AppSecrets.kakaoNativeAppKey)
        // 링크 SDK 는 여기서 켜야 재설치 직후(deferred) 매칭이 첫 실행에 걸린다 — 화면이 뜬 뒤면 늦다.
        deeplinkClient.start(AppSecrets.chottuLinkAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onOpenURL { url in
                    // 우리 링크(커스텀 스킴·유니버설 링크)만 AppFeature 로 — 그 외(kakao{KEY}://)는
                    // 카카오 SDK 콜백 현행 유지. 세부 판정(경로·토큰)은 파서 몫.
                    if url.scheme == "hilit" {
                        store.send(.deeplinkReceived(url))
                    } else if url.host?.lowercased() == GuestFeedbackShareLink.host {
                        // 진입은 원본 URL 로 **바로** 한다 — 설치 상태에선 iOS 가 쿼리를 그대로 주므로
                        // SDK 왕복(서드파티 네트워크)을 화면 진입의 선행조건으로 만들 이유가 없다.
                        // SDK 에 넘기는 건 클릭 어트리뷰션 몫이고, 그 결과가 늦게·따로 와도 이미 뜬 화면을
                        // 갈아치우지 않는다(AppFeature 가 진행 중 평가를 덮지 않는다).
                        store.send(.deeplinkReceived(url))
                        deeplinkClient.handle(url)
                    } else {
                        authClient.handleOpenURL(url)
                    }
                }
        }
    }
}

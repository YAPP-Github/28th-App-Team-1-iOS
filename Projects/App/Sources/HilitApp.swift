import Core
import Domain
import DomainAuthInterface
import Feature
import Shared

import SwiftUI
import ComposableArchitecture

@main
struct HilitApp: App {
    @Dependency(\.authClient) var authClient

    init() {
        authClient.configure(AppSecrets.kakaoNativeAppKey)
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
            // lifecycle 이벤트 → auth seam 연결. 어느 SDK가 URL을 소비하는지는 App이 모른다.
            .onOpenURL { url in
                authClient.handleOpenURL(url)
            }
        }
    }
}

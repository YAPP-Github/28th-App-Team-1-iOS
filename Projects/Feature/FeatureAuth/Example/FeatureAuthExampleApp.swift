//
//  FeatureAuthExampleApp.swift
//  FeatureAuthExample
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import FeatureAuthImplementation
import SwiftUI

/// Example 전용 미니 루트. 실제 앱에서 AppFeature(루트 게이트)가 하는 delegate 수신을 흉내내
/// 로그인 성공을 눈으로 확인할 수 있게 한다 — 없으면 delegate가 허공에 방출돼 화면 변화가 없다.
@Reducer
struct ExampleRoot {
    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        var isSignedIn = false
    }

    enum Action {
        case auth(AuthFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Reduce { state, action in
            switch action {
            case .auth(.delegate(.signedIn)):
                state.isSignedIn = true
                return .none
            case .auth:
                return .none
            }
        }
    }
}

struct ExampleRootView: View {
    @Bindable var store: StoreOf<ExampleRoot>

    var body: some View {
        if store.isSignedIn {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("로그인 성공")
                    .font(.headline)
                Text("실제 앱은 여기서 provider가 발급한 자격증명을 signIn 반환값으로 받는다 (Example은 스텁)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
        }
    }
}

@main
struct FeatureAuthExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRootView(
                store: Store(initialState: ExampleRoot.State()) {
                    ExampleRoot()
                } withDependencies: {
                    // Example 그래프에는 DomainAuthImplementation(liveValue)이 없다 — Interface까지만
                    // 링크되므로 이 스텁이 없으면 testValue(unimplemented)로 떨어진다.
                    // 1초 지연: 로딩 중 버튼 비활성화(반투명) 상태를 눈으로 확인할 수 있게.
                    $0.authClient = AuthClient(
                        configure: { _ in },
                        handleOpenURL: { _ in },
                        signIn: { provider in
                            try await Task.sleep(for: .seconds(1))
                            switch provider {
                            case .kakao:
                                return .kakao(
                                    accessToken: "example-access-token",
                                    refreshToken: "example-refresh-token"
                                )
                            case .apple:
                                return .apple(
                                    identityToken: "example-identity-token",
                                    authorizationCode: "example-authorization-code"
                                )
                            }
                        }
                    )
                }
            )
        }
    }
}

//
//  FeatureAuthExampleApp.swift
//  FeatureAuthExample
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainConsentInterface
import DomainJobInterface
import FeatureAuthImplementation
import SwiftUI

/// Example 전용 미니 루트. 실제 앱에서 AppFeature(루트 게이트)가 하는 delegate 수신을 흉내내
/// 가입 플로우 완주(소셜 로그인 → 약관 → 이름 → 직군 → 연차 → 등록 완료)를 눈으로 확인한다.
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
                Text("가입 플로우 완료")
                    .font(.headline)
                Text("실제 앱은 AppFeature 가 delegate(.signedIn)을 받아 홈으로 전환한다 (Example은 스텁)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
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
                    // 서버 세션 계열(login·refresh·logout·check)은 previewValue 스텁을 그대로 쓰고,
                    // 이 Example 이 시연하는 signIn 만 지연 붙인 스텁으로 교체한다.
                    var authClient = AuthClient.previewValue
                    authClient.signIn = { provider in
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
                    $0.authClient = authClient
                    // 약관 화면(A1)이 진입 시 항목을 조회하고 제출까지 한다 — 네트워크 없이 도는 스텁.
                    $0.consentClient = .previewValue
                    // 가입 온보딩 직군 선택 — 네트워크 없이 도는 고정 목록.
                    $0.jobClient = JobClient(jobs: {
                        [
                            Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
                            Job(jobId: 2, jobRole: "ANDROID", label: "Android"),
                            Job(jobId: 3, jobRole: "IOS", label: "iOS"),
                            Job(jobId: 4, jobRole: "FRONTEND", label: "프론트엔드"),
                            Job(jobId: 5, jobRole: "DATA_ENGINEER", label: "데이터 엔지니어"),
                            Job(jobId: 6, jobRole: "INFRA_SRE", label: "인프라 ⋅ SRE")
                        ]
                    })
                }
            )
        }
    }
}

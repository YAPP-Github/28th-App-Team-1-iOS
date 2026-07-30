//
//  HomeDefaultView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SwiftUI

/// Figma «HomeDefault» — 기본 상태 스텁. 시안 수령 시 잔여 표시 + 위젯 3종(연습 진행·면접 기록·마이페이지)으로 채운다.
/// dev 임시 버튼 2개는 위젯①(면접 시작)·마이페이지 로그아웃이 정식 배선되면 제거한다.
@ViewAction(for: HomeFeature.self)
struct HomeDefaultView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        VStack(spacing: 16) {
            Text("HomeDefault")

            // dev 전용 임시 진입 — 온보딩 본체 통합 전까지 실서버 API 확인용. 배포 계에선 숨겨진다.
            if store.showsOnboardingEntry {
                Button("온보딩 시작 (dev)") {
                    send(.userTappedOnboarding)
                }
                .buttonStyle(.borderedProminent)
            }

            // dev 디버그 — 서버 로그아웃 + 토큰·온보딩 draft 전체 삭제 후 첫 로그인 화면으로. 배포 계에선 숨겨진다.
            if store.showsDebugLogout {
                Button("로그아웃 (dev)", role: .destructive) {
                    send(.userTappedLogout)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("HomeDefault — dev 버튼") {
    HomeDefaultView(
        store: Store(initialState: HomeFeature.State(showsOnboardingEntry: true, showsDebugLogout: true)) {
            HomeFeature()
        }
    )
}

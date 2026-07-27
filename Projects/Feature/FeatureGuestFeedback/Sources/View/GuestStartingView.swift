//
//  GuestStartingView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// @lat: [[feedback#G4 게스트 평가]]
/// 면접 시작 로딩 연출(Figma `[4] 온보딩 - 면접 시작 로딩`, node 1855:8702).
/// "평가를 위해 [태도]에 집중해서 시청해 주세요" 안내를 화면 중앙에 얹는다.
/// 별도 화면이 아니라 평가 화면 위 **블러 오버레이** — 시안대로 아래 평가 화면이 블러 너머로 비친다
/// (조립은 GuestFeedbackView.evaluationPhase). 표시 전용 — 리듀서가 `videoReady`(약 1초) 연출을 마치면
/// evaluating 으로 넘어가고, 이 오버레이는 페이드아웃하며 걷힌다(Flow 1 — 세그먼트 바 슬라이드업과 동시, 별도 액션 없음).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestStartingView: View {
    let store: StoreOf<GuestFeedbackFeature>

    var body: some View {
        ZStack {
            // Figma 딤 layer(Rectangle 76148) 실측 — 블랙 60% + background blur 40. 대응 토큰 없어 리터럴.
            // SwiftUI 에 순수 backdrop blur 공개 API 가 없어 ultraThinMaterial 로 근사한다.
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            guidanceCopy
                .padding(.horizontal, .ds(.p20))
        }
    }

    // MARK: - Guidance copy (중앙 정렬 · 2행 · 그린 마커) — Figma head3_b_24, 시안에 스피너는 없다.

    private var guidanceCopy: some View {
        VStack(spacing: 0) {
            // 그린 형광펜 마커 — DS HighlightedText(Figma highlighted-text), 온보딩과 동일.
            // 다크 배경이라 강조 밖 글자만 흰색으로 올린다.
            HighlightedText("평가를 위해 태도에", plainForeground: Color.BlackWhite.white)
                .hilight("태도")
            Text("집중해서 시청해 주세요")
                .dsTypography(.head3)
                .foregroundStyle(Color.BlackWhite.white)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    var state = GuestFeedbackFeature.State(token: "preview")
    state.phase = .starting
    let store = Store(initialState: state) { GuestFeedbackFeature() }
    // 실제 조립(GuestFeedbackView.startingPhase)처럼 평가 화면 위에 얹어 블러 투과를 확인한다.
    return GuestEvaluationView(store: store)
        .allowsHitTesting(false)
        .overlay { GuestStartingView(store: store) }
        .preferredColorScheme(.dark)
}

//
//  InterviewReportPendingView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Interview_ReportPending — 시안 미출, 실패 화면 계열 흰 배경 중앙 정렬 임시 레이아웃 (시안 확정 시 교체).
// 대기 연출은 «협의 가능»(PRD §3.8) — 임시 생략.
// @ViewAction 매크로가 send(_:) 를 제공한다.
@ViewAction(for: InterviewReportPendingFeature.self)
public struct InterviewReportPendingView: View {
    @Bindable public var store: StoreOf<InterviewReportPendingFeature>

    public init(store: StoreOf<InterviewReportPendingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: .ds(.p8)) {
                Text("리포트를 만들고 있어요")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.HilitBlack.b800)
                Text("잠시만 기다려주세요")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            ButtonLarge("홈으로", .bottom) {
                send(.userTappedGoHome)
            }
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        // 진입이 조용한 영상 업로드를 연다 — 화면에 드러나는 변화는 없다(스펙 §④).
        .onAppear { send(.onAppear) }
    }
}

#Preview {
    InterviewReportPendingView(
        store: Store(initialState: InterviewReportPendingFeature.State()) {
            InterviewReportPendingFeature()
        }
    )
}

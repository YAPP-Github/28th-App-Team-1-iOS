//
//  ReportPeerFeedbackView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 리포트 피드백 자리표시 뷰 — 골격(내비바·본문·하단 CTA)만 두고 본문은 비워 뒀다.
// Figma 가 오면 디자인 토큰·공용 컴포넌트로 채운다 (.claude/design.md).
@ViewAction(for: ReportPeerFeedbackFeature.self)
public struct ReportPeerFeedbackView: View {
    @Bindable public var store: StoreOf<ReportPeerFeedbackFeature>

    public init(store: StoreOf<ReportPeerFeedbackFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer()
            Text("지인 피드백")
                .dsTypography(.head3)
                .foregroundStyle(Color.Gray.g800)
            Text("Part 4.5 스펙 대기")
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g500)
                .padding(.top, 8)
            Spacer()
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { send(.onAppear) }
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Image.Ic.close
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.HilitBlack.b800)
                    .rotationEffect(.degrees(45)) // TODO: 뒤로(chevron) 아이콘 에셋 추가 시 교체
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Button {
                send(.userTappedClose)
            } label: {
                Image.Ic.close
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.HilitBlack.b800)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

}

#Preview("지인 피드백") {
    ReportPeerFeedbackView(
        store: Store(initialState: ReportPeerFeedbackFeature.State()) {
            ReportPeerFeedbackFeature()
        }
    )
}

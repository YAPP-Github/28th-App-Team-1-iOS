//
//  ReportFinalView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 리포트 최종 자리표시 뷰 — 골격(내비바·본문·하단 CTA)만 두고 본문은 비워 뒀다.
// Figma 가 오면 디자인 토큰·공용 컴포넌트로 채운다 (.claude/design.md).
@ViewAction(for: ReportFinalFeature.self)
public struct ReportFinalView: View {
    @Bindable public var store: StoreOf<ReportFinalFeature>

    public init(store: StoreOf<ReportFinalFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer()
            Text("최종 보고서")
                .dsTypography(.head3)
                .foregroundStyle(Color.GrayScale.g800)
            Text("Part 4.6 스펙 대기")
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g500)
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
                Image.Cancel.default24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(45)) // TODO: 뒤로(chevron) 아이콘 에셋 추가 시 교체
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.default24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

}

#Preview("최종 보고서") {
    ReportFinalView(
        store: Store(initialState: ReportFinalFeature.State()) {
            ReportFinalFeature()
        }
    )
}

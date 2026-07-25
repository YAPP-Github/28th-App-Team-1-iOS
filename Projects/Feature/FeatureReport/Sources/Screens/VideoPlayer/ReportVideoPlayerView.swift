//
//  ReportVideoPlayerView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 리포트 영상 플레이어 자리표시 뷰 — 골격(내비바·본문·하단 CTA)만 두고 본문은 비워 뒀다.
// Figma 가 오면 디자인 토큰·공용 컴포넌트로 채운다 (.claude/design.md).
@ViewAction(for: ReportVideoPlayerFeature.self)
public struct ReportVideoPlayerView: View {
    @Bindable public var store: StoreOf<ReportVideoPlayerFeature>

    public init(store: StoreOf<ReportVideoPlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer()
            Text("영상 플레이어")
                .dsTypography(.head3)
                .foregroundStyle(Color.Gray.g800)
            Text("2/4 — 디자인 연결 예정")
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g500)
                .padding(.top, 8)
            Spacer()
            continueButton
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

    private var continueButton: some View {
        Button {
            send(.userTappedContinue)
        } label: {
            Text("계속하기")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.HilitBlack.b800.ignoresSafeArea(edges: .bottom))
    }
}

#Preview("영상 플레이어") {
    ReportVideoPlayerView(
        store: Store(initialState: ReportVideoPlayerFeature.State()) {
            ReportVideoPlayerFeature()
        }
    )
}

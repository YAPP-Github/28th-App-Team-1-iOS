//
//  GuestPlaybackProgressBar.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/13.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 구간 진행바 — 칸 하나 = 질문 턴, 폭은 길이에 비례, 탭하면 그 질문 시작으로 이동한다.
/// 리포트 플레이어의 같은 바(Figma 443:7857)와 같은 생김새: 지난 칸은 g600 판에 그린이 꽉 차고,
/// 재생 중인 칸만 왼쪽부터 채워진다(모서리 0).
///
/// **서버가 질문 경계를 주기 전까지는 칸이 하나**고, 그 대체 칸은 이동 대상이 아니라 탭을 막는다
/// (`docs/work/guest-feedback-question-boundaries.md`). 배속·±10초 건너뛰기는 이 화면에 없다.
///
/// **재생 시각을 읽는 유일한 뷰**다. 0.2초마다 오는 시각 갱신이 플레이어 본체 body 까지 번지면
/// 영상 위 모든 계층이 초당 다섯 번 다시 그려지므로, 시각 의존을 여기 가둔다.
struct GuestPlaybackProgressBar: View {
    let store: StoreOf<GuestVideoPlaybackFeature>

    var body: some View {
        let chunks = store.progressChunks
        let totalDuration = chunks.reduce(0) { $0 + $1.duration }
        return GeometryReader { proxy in
            let available = max(0, proxy.size.width - Self.spacing * CGFloat(chunks.count - 1))
            HStack(spacing: Self.spacing) {
                ForEach(chunks) { chunk in
                    let ratio = totalDuration > 0 ? chunk.duration / totalDuration : 1
                    cell(chunk, width: available * ratio)
                }
            }
        }
        .frame(height: Self.height)
    }

    private func cell(_ chunk: GuestPlaybackChunk, width: CGFloat) -> some View {
        Button {
            store.send(.view(.userTappedChunk(index: chunk.id)))
        } label: {
            Rectangle()
                .fill(Color.GrayScale.g600)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.HilitGreen.g500)
                        .frame(width: width * chunk.fillRatio(at: store.currentTime))
                }
                .frame(width: width, height: Self.height)
        }
        .buttonStyle(.plain)
        .disabled(!store.hasQuestionSections)
    }

    // @ds(layout): 6 — 진행바 칸 높이. spacing 스케일(4·8·…)에 6 이 없다
    private static let height: CGFloat = 6
    // @ds(spacing): 6 — 진행바 칸 사이 간격. 같은 이유로 토큰 없음
    private static let spacing: CGFloat = 6
}

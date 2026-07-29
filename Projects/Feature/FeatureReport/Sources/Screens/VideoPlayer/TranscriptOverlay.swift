//
//  TranscriptOverlay.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 플레이어의 대본 오버레이 — Figma «Report_VideoPlayer_TranscriptOverlay»(2121:5998).
/// 하단에서 올라오는 그라데이션 위에 답변 대본을 쌓고, 현재 재생 중인 답변만 흰색으로 띄운다.
/// 하이라이트 구간의 색·밴드·부분 탭은 공용 `TranscriptText` 가 담당한다(리포트 카드와 같은 규약).
struct TranscriptOverlay: View {
    let lines: [VideoTranscript.Line]
    let currentLineID: VideoTranscript.Line.ID?
    /// (카드 인덱스, 구간 인덱스) — 상세 시트를 열 재료.
    let onHighlightTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            transcript
                .frame(height: Self.overlayHeight)
                // 위로 갈수록 대본이 사라진다 — 영상 얼굴을 가리지 않기 위한 Figma 그라데이션.
                .background(Self.backgroundGradient)
                .mask(Self.fadeMask)
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Self.lineSpacing) {
                    ForEach(lines) { line in
                        TranscriptText(
                            transcript: line.text,
                            spans: line.spans,
                            // 지금 재생 중인 답변만 흰색 — 나머지는 물러난다.
                            baseColor: line.id == currentLineID
                                ? Color.BlackWhite.white
                                : Color.GrayScale.g400,
                            onTapSpan: { spanIndex in onHighlightTap(line.id, spanIndex) }
                        )
                        .id(line.id)
                    }
                }
                .padding(.horizontal, .ds(.p20))
                .padding(.vertical, .ds(.p24))
            }
            // 재생이 다음 답변으로 넘어가면 그 줄로 따라간다.
            .onChange(of: currentLineID) { _, id in
                guard let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    /// Figma 그라데이션 (투명 → 56% → b900).
    private static let backgroundGradient = LinearGradient(
        stops: [
            .init(color: Color.HilitBlack.b900.opacity(0), location: 0),
            .init(color: Color.HilitBlack.b900.opacity(0.56), location: 0.331),
            .init(color: Color.HilitBlack.b900, location: 0.909)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 위쪽 대본이 흐려지며 사라지는 마스크.
    private static let fadeMask = LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.16)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 대본이 차지하는 높이 (Figma 524/812).
    private static let overlayHeight: CGFloat = 524
    private static let lineSpacing: CGFloat = 20
}

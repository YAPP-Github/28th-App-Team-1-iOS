//
//  TranscriptOverlay.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 플레이어의 대본 오버레이 — Figma «Report_VideoPlayer_TranscriptOverlay»(443:7902).
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
                // 위로 갈수록 대본이 사라진다 — 영상 얼굴을 가리지 않기 위한 Figma 스크림.
                // 램프 비율은 DS 가 소유하고 덮는 높이만 화면 실측으로 덮는다.
                .background(VideoOverlay(.darkOpen, height: Self.overlayHeight))
                .mask(Self.fadeMask)
        }
        // 하단 세이프에어리어까지 램프 «끝 색»을 깐다 — 오버레이는 세이프에어리어 안에서 끝나
        // 그 아래로 영상이 다시 드러난다(홈 인디케이터 자리에 색바가 보였다). 램프는 90.9% 에서
        // 이미 b900 에 도달하므로 끝 색 한 판으로 이어 붙이면 이음선이 보이지 않는다.
        .background(alignment: .bottom) { safeAreaFill }
    }

    /// 세이프에어리어 메움 — 높이가 기기마다 다르니 넉넉히 깔고 아래로 밀어낸다
    /// (뷰의 «그리기» 는 세이프에어리어 밖에도 나가고, 레이아웃만 안쪽에 머문다).
    private var safeAreaFill: some View {
        Color.HilitBlack.b900
            .frame(height: Self.safeAreaFillHeight)
            .offset(y: Self.safeAreaFillHeight)
            .allowsHitTesting(false)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .ds(.p20)) {
                    ForEach(lines) { line in
                        TranscriptText(
                            transcript: line.text,
                            spans: line.spans,
                            // 지금 재생 중인 답변만 흰색 — 나머지는 물러난다.
                            baseColor: line.id == currentLineID
                                ? Color.BlackWhite.white
                                : Color.GrayScale.g400,
                            // 오버레이는 영상 위 어두운 판이라 밴드가 카드보다 한 단 어둡다(시안 443:7906).
                            bandColor: Color.GrayScale.g900,
                            onTapSpan: { spanIndex in onHighlightTap(line.id, spanIndex) }
                        )
                        .id(line.id)
                    }
                }
                .padding(.horizontal, .ds(.p20))
                .padding(.top, .ds(.p24))
                // 하단 바(진행바 + 대본 버튼)를 비우고 그 위로 44 를 더 띄운다.
                .padding(.bottom, Self.bottomInset)
                // **대본은 아래에 붙는다** — 줄이 적어도 화면 가운데 떠 있지 않고 마지막 줄이
                // 진행바 44 위에 선다(시안 443:7906 아래끝 665 vs 진행바 709). 줄이 넘치면 스크롤.
                .frame(minHeight: Self.overlayHeight, alignment: .bottom)
            }
            // 재생이 다음 답변으로 넘어가면 그 줄로 따라간다.
            .onChange(of: currentLineID) { _, id in
                guard let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    /// 위쪽 대본이 흐려지며 사라지는 마스크 — 시안은 맨 위 줄에만 텍스트 그라데이션(443:7916)을
    /// 걸었지만, 줄 수가 유동이라 오버레이 상단 16% 에 마스크로 걸어 같은 효과를 만든다.
    private static let fadeMask = LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.16)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // @ds(layout): 524 — 대본이 차지하는 높이 (Figma 443:7904, 524/812)
    private static let overlayHeight: CGFloat = 524
    // @ds(layout): 78 + 44 — 하단 바가 덮는 높이(진행바 6 + 간격 16 + 버튼 44 + 아래 여백 12)에
    // 시안의 진행바~대본 간격 44 를 더한 값. 플레이어 하단 바 수치의 합이라 토큰 하나로 대응되지 않는다
    private static let bottomInset: CGFloat = 78 + 44
    /// 세이프에어리어 메움 높이 — 실제 인셋(홈 인디케이터 34 안팎)보다 넉넉하게. 디자인 값이 아니라
    /// «아래로 넘치게 그린다» 는 여유분이라 토큰 대상이 아니다.
    private static let safeAreaFillHeight: CGFloat = 80
}

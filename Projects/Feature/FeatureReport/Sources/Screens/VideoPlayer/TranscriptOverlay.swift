//
//  TranscriptOverlay.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

// Figma «Report_VideoPlayer_TranscriptOverlay» 443:7902(긴 턴 — 스크롤+페이드) · 443:7941(짧은 턴)
/// 플레이어의 대본 오버레이 — **현재 질문 턴 하나**의 문장을 재생 시각까지 쌓는다.
///
/// 규칙 하나로 두 진입 경로를 다 덮는다: «시작 시각이 지난 문장만 그리고, 현재 문장은 항상 맨 아래».
/// 처음부터 재생하면 문장이 밑에서 차곡차곡 올라오고, 하이라이트 점프로 중간부터 들으면
/// 그 시점까지의 문장이 이미 쌓인 채 목표 문장이 바닥에 선다 — 별도 분기가 없다.
/// 위로 밀려난 문장은 상단 페이드로 사라지고, 넘치면 스크롤로 되짚을 수 있다.
/// 문장에는 **면접관 질문도 섞여** 시각 순으로 선다 — 질문과 답변은 같은 모양으로 그린다.
/// 하이라이트 구간의 색·밴드·부분 탭은 공용 `TranscriptText` 가 담당한다(리포트 카드와 같은 규약).
struct TranscriptOverlay: View {
    /// 현재 턴 대본. nil 이면(첫 발화 전) 스크림만 깐다.
    let line: VideoTranscript.Line?
    /// 현재 문장 순번 — 여기까지만 그리고, 이 문장만 흰색으로 띄운다.
    let currentSentenceIndex: Int
    /// (카드 인덱스, 구간 인덱스) — 상세 시트를 열 재료.
    let onHighlightTap: (Int, Int) -> Void

    var body: some View {
        // 그릴 문장이 없으면 아무것도 얹지 않는다 — 글자 없는 스크림이 화면을 덮고 하단 램프까지
        // 가로채면 하단 바 그라데이션이 어긋난다. 노출 판정은 리듀서(`isTranscriptOverlayVisible`)가
        // 하고 여기는 마지막 방어선이다.
        if !visibleSentences.isEmpty {
            overlay
        }
    }

    private var overlay: some View {
        GeometryReader { proxy in
            // 대본 최고점은 네비 바에서 182 아래 — 여기서 위쪽은 영상 얼굴 자리라 비워 둔다.
            // (네비 바는 `.hilitNavigationBar` 가 safeAreaInset 으로 얹어 이미 이 영역 밖이다.)
            let height = max(0, proxy.size.height - Self.topInset)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                transcript(height: height)
                    // 위로 갈수록 대본이 사라진다 — 영상 얼굴을 가리지 않기 위한 Figma 스크림.
                    // 램프 비율은 DS 가 소유하고 덮는 높이만 화면 실측으로 덮는다.
                    .background(VideoOverlay(.darkOpen, height: height))
                    .mask(Self.fadeMask)
            }
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

    /// 시작 시각이 지난 문장들 — 화면이 그리는 전부. 다음 문장은 시각이 닿기 전엔 없다.
    private var visibleSentences: [VideoTranscript.Sentence] {
        guard let line else { return [] }
        return Array(line.sentences.prefix(currentSentenceIndex + 1))
    }

    private func transcript(height: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .ds(.p20)) {
                    ForEach(visibleSentences) { sentence in
                        text(sentence).id(sentence.id)
                    }
                }
                .padding(.horizontal, .ds(.p20))
                .padding(.top, .ds(.p24))
                // 하단 바(진행바 + 대본 버튼)를 비우고 그 위로 44 를 더 띄운다.
                .padding(.bottom, Self.bottomInset)
                // **대본은 아래에 붙는다** — 짧은 턴(443:7941)은 마지막 줄이 진행바 44 위에 서고,
                // 긴 턴(443:7902)은 위로 넘쳐 페이드 속으로 밀려난다.
                .frame(minHeight: height, alignment: .bottom)
            }
            .frame(height: height)
            // 새 문장이 오면 바닥으로 스냅 — 위로 되짚어 읽던 중이어도 재생을 따라간다(현재 문장 = 바닥 규칙).
            .onChange(of: currentSentenceIndex) { _, index in
                withAnimation { proxy.scrollTo(index, anchor: .bottom) }
            }
            // 턴이 바뀌면 대본이 통째로 갈린다 — 새 턴의 현재 문장부터 다시.
            .onChange(of: line?.id) { _, _ in
                proxy.scrollTo(currentSentenceIndex, anchor: .bottom)
            }
            // 점프 진입 — 목표 문장이 바닥에 서고 앞 문장들이 위로 쌓인 채 시작한다.
            .onAppear { proxy.scrollTo(currentSentenceIndex, anchor: .bottom) }
        }
    }

    /// 문장 한 줄 — 면접관 질문도 내 답변과 같은 모양으로 그린다(2026-08-10, 앞의 Q 배지 폐기).
    private func text(_ sentence: VideoTranscript.Sentence) -> some View {
        TranscriptText(
            transcript: sentence.text,
            spans: sentence.spans,
            // 지금 재생 중인 문장만 흰색 — 지난 문장은 물러난다(면접관 질문도 같은 규칙).
            baseColor: sentence.id == currentSentenceIndex
                ? Color.BlackWhite.white
                : Color.GrayScale.g400,
            // 오버레이는 영상 위 어두운 판이라 밴드가 카드보다 한 단 어둡고(시안 443:7906),
            // 잘함 톤도 한 단 짙다(443:7919 #008A9F — 카드·시트의 p500 과 다른 판).
            bandColor: Color.GrayScale.g900,
            goodToneColor: Color.Positive.p800,
            onTapSpan: { spanIndex in
                guard let line, sentence.spanIndices.indices.contains(spanIndex) else { return }
                onHighlightTap(line.id, sentence.spanIndices[spanIndex])
            }
        )
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

    // @ds(layout): 182 — 대본 최고점의 네비 바 아래 간격 (Figma 443:7902 대본 상단 281 = 네비 끝 99 + 182)
    private static let topInset: CGFloat = 182
    // @ds(layout): 78 + 44 — 하단 바가 덮는 높이(진행바 6 + 간격 16 + 버튼 44 + 아래 여백 12)에
    // 시안의 진행바~대본 간격 44 를 더한 값. 플레이어 하단 바 수치의 합이라 토큰 하나로 대응되지 않는다
    private static let bottomInset: CGFloat = 78 + 44
    /// 세이프에어리어 메움 높이 — 실제 인셋(홈 인디케이터 34 안팎)보다 넉넉하게. 디자인 값이 아니라
    /// «아래로 넘치게 그린다» 는 여유분이라 토큰 대상이 아니다.
    private static let safeAreaFillHeight: CGFloat = 80
}

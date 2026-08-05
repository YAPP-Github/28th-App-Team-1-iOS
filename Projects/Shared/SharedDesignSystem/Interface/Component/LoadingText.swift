//
//  LoadingText.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

import SwiftUI

/// 로딩 문구 롤링 줄 — Figma «loading/text» (인스턴스 439:10225 롤링 / 439:10226 정착).
///
/// 문구들을 가로 한 줄에 간격 6 으로 촘촘히 늘어놓고(`sub7`) **활성 문구를 컨테이너 중앙에 맞춘다** —
/// 앞뒤 문구는 좌우로 넘쳐 잘린다(시안도 375 폭을 넘겨 흐른다). 활성 인덱스가 바뀌면 줄이
/// 옆으로 미끄러지는 게 롤링이다. 비활성은 g700, 활성은 롤링 중 g600 · 정착 g50.
///
/// **모션 스펙은 시안에 없다** — Figma 는 두 인스턴스에 주석만 달아뒀다
/// (439:10225 «컨테이너 애니메이션» / 439:10226 «멈추고 샤이닝 효과»).
/// 롤링은 활성 인덱스 전환의 easeInOut 슬라이드, 샤이닝은 불투명도 왕복으로 근사했다 —
/// 지속시간·커브·샤이닝 형태(그라디언트 스윕인지 밝기 펄스인지)는 확정 후 재조정한다.
///
/// 문구는 호출부 문자열이다 — 시안의 «로딩 문구를 입력해주세요» 는 placeholder.
/// 폭은 호출부 몫(시안 375 = 화면 폭) — 넘친 문구는 이 뷰가 자기 폭으로 자른다.
public struct LoadingText: View {
    /// Figma 인스턴스 2종 — 활성 문구의 색과 모션이 함께 움직인다.
    public enum Phase: Sendable, CaseIterable {
        /// 롤링 중 — 활성 문구 g600 (439:10225).
        case rolling
        /// 멈춤 — 활성 문구 g50 + 샤이닝 (439:10226).
        case settled
    }

    private let phrases: [String]
    private let activeIndex: Int
    private let phase: Phase

    @State private var isShining = false

    /// - Parameters:
    ///   - phrases: 늘어놓을 문구들. 순서가 롤링 순서다.
    ///   - activeIndex: 중앙에 오는 문구의 인덱스. 범위를 벗어나면 양끝으로 잠근다.
    ///   - phase: 롤링 중인가 멈췄는가.
    public init(_ phrases: [String], activeIndex: Int, phase: Phase = .rolling) {
        self.phrases = phrases
        self.activeIndex = activeIndex
        self.phase = phase
    }

    public var body: some View {
        // 중앙 정렬을 뷰 계층이 아니라 배치로 푼다 — 문구 폭을 실측해 오프셋을 계산하는
        // (PreferenceKey + @State) 왕복 없이, Layout 이 한 패스에서 활성 문구를 중앙에 놓는다.
        ActiveCenteredRow(spacing: Metric.gap, activeIndex: clampedIndex) {
            ForEach(Array(phrases.enumerated()), id: \.offset) { index, phrase in
                phraseText(phrase, isActive: index == clampedIndex)
            }
        }
        .clipped()
        .animation(.easeInOut(duration: Metric.rollDuration), value: clampedIndex)
        .onAppear { syncShining() }
        .onChange(of: phase) { _, _ in syncShining() }
    }

    /// 문구 한 개 — 줄바꿈·말줄임 없이 이상 폭을 그대로 쓴다(넘친 만큼은 바깥에서 잘린다).
    private func phraseText(_ phrase: String, isActive: Bool) -> some View {
        Text(phrase)
            .dsTypography(.sub7)
            .foregroundStyle(isActive ? activeForeground : Color.GrayScale.g700)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .opacity(isActive && isShining ? Metric.shineOpacity : 1)
    }

    /// 활성 문구 색 — Figma 두 인스턴스의 유일한 색 차이.
    private var activeForeground: Color {
        switch phase {
        case .rolling: Color.GrayScale.g600
        case .settled: Color.GrayScale.g50
        }
    }

    /// 활성 인덱스를 배열 범위로 잠근다 — 호출부의 off-by-one 이 빈 화면이 되지 않게.
    private var clampedIndex: Int {
        guard !phrases.isEmpty else { return 0 }
        return min(max(activeIndex, 0), phrases.count - 1)
    }

    /// 샤이닝은 `.settled` 에서만 왕복한다 — 롤링 중엔 즉시 꺼서 불투명도를 1 로 되돌린다.
    private func syncShining() {
        guard phase == .settled else {
            isShining = false
            return
        }
        withAnimation(
            .easeInOut(duration: Metric.shineDuration).repeatForever(autoreverses: true)
        ) {
            isShining = true
        }
    }

    private enum Metric {
        /// 문구 사이 간격 6 — 스케일 밖 값이라 토큰이 없다(Figma gap).
        static let gap: CGFloat = 6
        /// 롤링 전환 시간 — 시안 미정, 화면 전환(0.3)과 같은 호흡으로 뒀다.
        static let rollDuration: Double = 0.3
        /// 샤이닝 한 방향 시간 — 시안 미정.
        static let shineDuration: Double = 0.8
        /// 샤이닝 최저 불투명도 — 시안 미정(밝기 펄스로 근사).
        static let shineOpacity: Double = 0.55
    }
}

/// 가로 한 줄 배치 — 간격을 두고 이어 붙이되 **활성 항목의 중앙을 컨테이너 중앙**에 맞춘다.
/// 폭은 제안을 그대로 받아(화면 폭) 넘친 항목은 좌우로 삐져나간다 — 자르는 건 호출부(`clipped`).
private struct ActiveCenteredRow: Layout {
    let spacing: CGFloat
    let activeIndex: Int

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let contentWidth = sizes.reduce(0) { $0 + $1.width }
            + spacing * CGFloat(max(0, sizes.count - 1))
        return CGSize(
            width: proposal.width ?? contentWidth,
            height: sizes.map(\.height).max() ?? 0
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        guard !sizes.isEmpty else { return }

        let index = min(max(activeIndex, 0), sizes.count - 1)
        // 줄 시작점 = 컨테이너 중앙 − (활성 항목 왼쪽까지 누적 폭) − (활성 항목 절반)
        let leading = sizes.prefix(index).reduce(0) { $0 + $1.width } + spacing * CGFloat(index)
        var x = bounds.midX - leading - sizes[index].width / 2

        for (subview, size) in zip(subviews, sizes) {
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
        }
    }
}

#Preview("롤링") {
    LoadingText(
        ["첫 번째 로딩 문구예요", "두 번째 로딩 문구", "세 번째 로딩 문구입니다"],
        activeIndex: 1
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.GrayScale.g800)
}

#Preview("정착 (샤이닝)") {
    LoadingText(
        ["첫 번째 로딩 문구예요", "두 번째 로딩 문구", "세 번째 로딩 문구입니다"],
        activeIndex: 2,
        phase: .settled
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.GrayScale.g800)
}

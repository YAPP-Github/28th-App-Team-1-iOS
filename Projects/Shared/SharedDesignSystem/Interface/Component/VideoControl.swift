//
//  VideoControl.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

import SwiftUI

/// 영상 재생 컨트롤 한 줄 — Figma «video-control» 435:830(`play`) / 435:837(`pause`).
///
/// 254×74 한 줄: 되감기(44 히트박스 안 34 아이콘) — 46 — 중앙 74 정사각 g500 판 — 46 — 빨리감기.
/// 판은 모서리 0(캡슐·라운드 아님)이고 안쪽 여백 20 이 34 아이콘을 74 로 키운다.
///
/// **Figma 변형 이름과 글리프가 뒤집혀 있다** — `video-control/play`(435:830) 안에는
/// `pause/34px/green` 이, `video-control/pause`(435:837) 안에는 `play/34px/green` 이 들어 있다.
/// 변형 이름이 «지금 상태»(재생 중)를 가리키는 것으로 읽고 `isPlaying` 으로 받는다:
/// `isPlaying == true` → 435:830(⏸ 글리프, 탭하면 멈춤). 이름이 아니라 글리프를 기준으로 골랐다
/// (사고 사례 8번 — Play/Stop 이 서로 바뀐 채 컴파일이 통과한 전례).
///
/// 시안의 backdrop blur 11.563 은 반영하지 않았다 — 판 배경 g500 이 완전 불투명(alpha 1)이라
/// 뒤를 흐려도 화면에 아무 차이가 없다.
/// 폭·위치는 호출부 몫 — 영상 위 어디에 얹히는지는 화면마다 다르다.
public struct VideoControl: View {
    private let isPlaying: Bool
    private let onSkipBackward: () -> Void
    private let onPlayPauseToggle: () -> Void
    private let onSkipForward: () -> Void

    /// - Parameters:
    ///   - isPlaying: 재생 중인가. `true` 면 중앙 판이 ⏸ 글리프(Figma 435:830), `false` 면 ▷(435:837).
    ///   - onSkipBackward: 되감기 탭. 몇 초를 되감는지는 호출부 몫(시안에 수치 없음).
    ///   - onPlayPauseToggle: 중앙 판 탭 — 재생/일시정지 전환.
    ///   - onSkipForward: 빨리감기 탭.
    public init(
        isPlaying: Bool,
        onSkipBackward: @escaping () -> Void,
        onPlayPauseToggle: @escaping () -> Void,
        onSkipForward: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.onSkipBackward = onSkipBackward
        self.onPlayPauseToggle = onPlayPauseToggle
        self.onSkipForward = onSkipForward
    }

    public var body: some View {
        HStack(spacing: Metric.gap) {
            skipButton(Image.SkipL.white34, action: onSkipBackward)
            playPausePlate
            skipButton(Image.SkipR.white34, action: onSkipForward)
        }
    }

    /// 되감기·빨리감기 — 34 글리프를 44 히트박스에 담는다(Figma 435:831·435:835).
    private func skipButton(_ icon: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .frame(width: Metric.hitBoxSide, height: Metric.hitBoxSide)
        }
        .buttonStyle(.plain)
    }

    /// 중앙 재생/일시정지 판 — g500 74 정사각(34 글리프 + p20), 모서리 0.
    private var playPausePlate: some View {
        Button(action: onPlayPauseToggle) {
            playPauseIcon
                .padding(.ds(.p20))
                .background(Color.HilitGreen.g500)
        }
        .buttonStyle(.plain)
    }

    /// 글리프는 «지금 상태»의 반대 동작을 그린다 — 재생 중이면 ⏸.
    private var playPauseIcon: Image {
        isPlaying ? Image.Pause.green34 : Image.Play.green34
    }

    private enum Metric {
        /// 아이콘 사이 간격 46 — 스케일 밖 값이라 토큰이 없다(Figma gap).
        static let gap: CGFloat = 46
        /// 스킵 버튼 히트박스 한 변 44 — 글리프(34)보다 큰 탭 영역.
        static let hitBoxSide: CGFloat = 44
    }
}

#Preview {
    VStack(spacing: .ds(.p40)) {
        VideoControl(
            isPlaying: true,
            onSkipBackward: {},
            onPlayPauseToggle: {},
            onSkipForward: {}
        )
        VideoControl(
            isPlaying: false,
            onSkipBackward: {},
            onPlayPauseToggle: {},
            onSkipForward: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}

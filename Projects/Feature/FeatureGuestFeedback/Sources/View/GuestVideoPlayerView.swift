//
//  GuestVideoPlayerView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import AVKit
import DomainGuestFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

/// 평가 화면 영상 — 몰입(풀블리드)/카드 두 렌더를 가진다.
/// 재생 위치는 리듀서 관심사가 아니라 AVPlayer 를 뷰 로컬로 보유한다 —
/// 몰입↔카드 전환에도 이 뷰가 구조상 같은 자리에 남아 재생이 끊기지 않는다.
struct GuestVideoPlayerView: View {
    let videoURL: URL?
    let boundaries: [QuestionBoundary]
    /// 몰입 렌더(시안 진입 상태) — 카드 크롬(라운드·비율 고정·경계 칩·확대 버튼) 없이 가용 영역을 채운다.
    var isImmersive = false
    /// 카드 모드 우하단 확대(⛶) 탭 — 평가 화면이 몰입 모드로 되돌린다.
    var onExpandTapped: () -> Void = {}

    @State private var player: AVPlayer?

    // Figma «[4] 객관식»(node 2150:7278) 영상: 256×432 세로 프레임 — 다크 평가 화면 위 중앙 정렬.
    // DS 에 영상 치수 토큰이 없어 Figma 원값을 리터럴 상수로 보존한다.
    private let videoAspectRatio: CGFloat = 256.0 / 432.0
    private let videoMaxHeight: CGFloat = 432

    var body: some View {
        Group {
            if isImmersive {
                immersiveSurface
            } else {
                cardSurface
            }
        }
        .onAppear {
            if player == nil, let videoURL {
                player = AVPlayer(url: videoURL)
            }
        }
        .onDisappear { player?.pause() }
    }

    // MARK: - 몰입 (풀블리드)

    private var immersiveSurface: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                placeholderContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.GrayScale.g900)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 카드 (라운드 프레임 + 경계 칩 + 확대 버튼)

    private var cardSurface: some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(videoAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: onExpandTapped) {
                            // DS `Expand.default24` — g200 사각 타일 + 흰 화살표가 에셋에 구워져 있어
                            // 뒤에 별도 배경(thinMaterial 원)을 깔지 않는다(코너 0 판이라 원이 어긋난다).
                            Image.Expand.default24
                        }
                        .padding(.ds(.p8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: videoMaxHeight)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.GrayScale.g900)
                    .aspectRatio(videoAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: videoMaxHeight)
                    .overlay { placeholderContent }
            }

            if player != nil, !boundaries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .ds(.p8)) {
                        ForEach(boundaries, id: \.turnLevel) { boundary in
                            boundaryChip(boundary)
                        }
                    }
                }
            }
        }
    }

    /// 영상 미도착 자리 — **시안에 없는 코드 전용 상태**다(Figma 에 placeholder 변형이 없다).
    /// 아이콘만 DS 로 맞춘다: `Video.disabled24`(g200 글리프) — 다크 판 위 «아직 없음» 톤.
    private var placeholderContent: some View {
        VStack(spacing: .ds(.p8)) {
            Image.Video.disabled24
            Text("영상을 준비 중이에요")
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g400)
        }
    }

    private func boundaryChip(_ boundary: QuestionBoundary) -> some View {
        Button {
            seek(to: boundary.startAt)
        } label: {
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text("Q\(boundary.turnLevel)")
                    .dsTypography(.body9)
                    .foregroundStyle(Color.BlackWhite.white)
                if let text = boundary.questionText {
                    Text(text)
                        .dsTypography(.body10)
                        .foregroundStyle(Color.GrayScale.g400)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, .ds(.p12))
            .padding(.vertical, .ds(.p8))
            // 다크 평가 배경 위 칩 — gray900 표면. DS 에 radius 토큰이 없어 리터럴 10pt 유지.
            .background(Color.GrayScale.g900, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        player?.play()
    }
}

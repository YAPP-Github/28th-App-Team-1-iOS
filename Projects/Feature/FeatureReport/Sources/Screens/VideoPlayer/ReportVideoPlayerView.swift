//
//  ReportVideoPlayerView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import AVKit
import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 영상 플레이어 1단계 — 진입 즉시 재생. STT 오버레이·장면 seek 는 서버 timestamp 확장 대기 (정의서 §8).
// 재생 위치는 리듀서 관심사가 아니라 AVPlayer 를 뷰 로컬로 보유한다 — 선례 `GuestVideoPlayerView`.
@ViewAction(for: ReportVideoPlayerFeature.self)
public struct ReportVideoPlayerView: View {
    @Bindable public var store: StoreOf<ReportVideoPlayerFeature>
    @State private var player: AVPlayer?

    public init(store: StoreOf<ReportVideoPlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            playerSurface
        }
        .background(Color.HilitBlack.b900.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            send(.onAppear)
            guard player == nil else { return }
            let player = AVPlayer(url: store.videoURL)
            // 진입 시각 지정(«이 장면 영상으로 보기») — 확장 전에는 항상 nil 이라 처음부터 재생한다.
            if let startAt = store.startAt {
                player.seek(to: CMTime(seconds: startAt, preferredTimescale: 600))
            }
            self.player = player
            player.play()
        }
        .onDisappear { player?.pause() }
        .sheet(item: $store.scope(state: \.highlightDetail, action: \.highlightDetail)) { store in
            ReportHighlightDetailView(store: store)
        }
        // 하이라이트 시트가 열리면 재생을 멈춘다 — 일시정지는 뷰 책임(리듀서는 시트만 올린다).
        .onChange(of: store.highlightDetail != nil) { _, isPresented in
            if isPresented { player?.pause() } else { player?.play() }
        }
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
                    .foregroundStyle(Color.BlackWhite.white)
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
                    .foregroundStyle(Color.BlackWhite.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

    @ViewBuilder
    private var playerSurface: some View {
        if let message = store.playbackFailureMessage {
            VStack {
                Spacer()
                Text(message)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g200)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let player {
            VideoPlayer(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Spacer()
        }
    }
}

#Preview("영상 플레이어") {
    ReportVideoPlayerView(
        store: Store(
            initialState: ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!
            )
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

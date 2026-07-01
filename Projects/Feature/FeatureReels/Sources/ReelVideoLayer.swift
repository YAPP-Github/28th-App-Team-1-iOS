//
//  ReelVideoLayer.swift
//  FeatureReels
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import SwiftUI

// 영상 레이어 — 실제 재생(ReelPlayerView) 또는 poster 폴백 + caption·우측 레일.
// scaleEffect/offset/clipShape 변환은 부모(ReelsView)가 progress 로 적용한다.
struct ReelVideoLayer: View {
    let store: StoreOf<ReelsFeature>

    var body: some View {
        ZStack {
            if let url = store.reel.videoURL {
                ReelPlayerView(url: url, isPlaying: store.isPlaying)
            } else {
                poster
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { store.send(.userTappedVideo) }

            if !store.isPlaying, store.reel.videoURL != nil {
                Image(systemName: "play.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(radius: 6)
            }

            HStack(alignment: .bottom) {
                caption
                Spacer(minLength: 12)
                rail
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var poster: some View {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.13, blue: 0.35), Color(red: 0.55, green: 0.18, blue: 0.42)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: 10) {
                Image(systemName: "film.stack")
                    .font(.system(size: 44, weight: .semibold))
                Text("reel_sample.mp4 를 Example/Resources 에 넣으면\n실제 영상이 재생됩니다")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding()
        }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("@\(store.reel.authorName)")
                .font(.subheadline.weight(.semibold))
            Text(store.reel.caption)
                .font(.footnote)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .shadow(radius: 4)
    }

    private var rail: some View {
        VStack(spacing: 22) {
            railIcon(system: "heart.fill", caption: countLabel(store.reel.likeCount))
            Button {
                store.send(.userTappedCommentButton)
            } label: {
                railIcon(system: "bubble.right.fill", caption: countLabel(store.reel.commentCount))
            }
            .buttonStyle(.plain)
            railIcon(system: "paperplane.fill", caption: "공유")
        }
        .foregroundStyle(.white)
    }

    private func railIcon(system: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: system)
                .font(.system(size: 26))
            Text(caption)
                .font(.caption2)
        }
        .shadow(radius: 3)
    }

    private func countLabel(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1f천", Double(count) / 1000)
        }
        return "\(count)"
    }
}

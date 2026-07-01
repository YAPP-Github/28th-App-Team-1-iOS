//
//  ReelPlayerView.swift
//  FeatureReels
//
//  Created by EunSeo on 26/07/02.
//

import AVKit
import SwiftUI

// AVPlayerLayer(.resizeAspectFill) 를 감싼 muted 자동재생 루프 뷰.
// isPlaying 바인딩으로 play/pause. AVKit 은 시스템 프레임워크라 별도 의존성 추가 불필요.
struct ReelPlayerView: UIViewRepresentable {
    let url: URL
    var isPlaying: Bool

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlaying(isPlaying)
    }

    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: Coordinator) {
        uiView.teardown()
    }

    final class PlayerUIView: UIView {
        // UIView.layerClass 는 override 가능한 `class` 타입 프로퍼티라 static 으로 대체 불가.
        // swiftlint:disable:next static_over_final_class
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }

        func configure(url: URL) {
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            queuePlayer.isMuted = true
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            playerLayer?.player = queuePlayer
            playerLayer?.videoGravity = .resizeAspectFill
            player = queuePlayer
            queuePlayer.play()
        }

        func setPlaying(_ playing: Bool) {
            guard let player else { return }
            if playing {
                player.play()
            } else {
                player.pause()
            }
        }

        func teardown() {
            player?.pause()
            looper = nil
            player = nil
            playerLayer?.player = nil
        }
    }
}

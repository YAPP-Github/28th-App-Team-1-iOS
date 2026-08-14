//
//  GuestVideoSurface.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/13.
//

import AVFoundation
import SwiftUI

/// 시스템 컨트롤 없는 재생 표면 — SwiftUI `VideoPlayer` 는 자체 컨트롤을 얹어 DS `VideoControl` 과 겹친다.
/// 담기는 방식이 몰입·카드에서 달라 `videoGravity` 를 호출부가 정한다:
/// 몰입은 화면을 꽉 채우고(`resizeAspectFill`), 카드는 세로 프레임 안에 온전히 들어와야 한다(`resizeAspect`).
struct GuestVideoSurface: UIViewRepresentable {
    let player: AVPlayer
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer?.player = player
        view.playerLayer?.videoGravity = gravity
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer?.player = player
        uiView.playerLayer?.videoGravity = gravity
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    }
}

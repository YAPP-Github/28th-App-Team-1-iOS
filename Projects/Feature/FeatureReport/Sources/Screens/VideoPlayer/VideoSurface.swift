//
//  VideoSurface.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import AVFoundation
import SwiftUI

/// 시스템 컨트롤 없는 재생 표면. SwiftUI `VideoPlayer` 는 자체 컨트롤을 얹어서
/// Figma 커스텀 컨트롤과 겹치기 때문에 `AVPlayerLayer` 를 직접 올린다.
/// 영상은 화면을 꽉 채운다(Figma 전면 비디오) — `resizeAspectFill`.
struct VideoSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer?.player = player
        view.playerLayer?.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer?.player = player
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    }
}

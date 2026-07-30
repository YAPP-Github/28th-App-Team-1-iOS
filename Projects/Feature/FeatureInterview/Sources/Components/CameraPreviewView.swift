//
//  CameraPreviewView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/28.
//

import AVFoundation
import DomainRecordingInterface
import SwiftUI

/// AVCaptureVideoPreviewLayer 를 backing layer 로 쓰는 프리뷰 뷰 — 핸들의 캡처 세션을 그대로 붙인다.
/// 전면 카메라 기본 미러링 사용 · 앱은 portrait 고정이라 회전 대응 없음.
struct CameraPreviewView: UIViewRepresentable {
    let handle: CameraPreviewHandle

    final class PreviewUIView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer {
            // layerClass 가 AVCaptureVideoPreviewLayer 이므로 이 캐스트는 항상 성립한다.
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = handle.session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = handle.session
    }
}

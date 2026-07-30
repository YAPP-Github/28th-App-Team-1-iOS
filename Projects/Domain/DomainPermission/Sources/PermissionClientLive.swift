//
//  PermissionClientLive.swift
//  DomainPermissionImplementation
//
//  Created by 서정원 on 26/07/27.
//

import AVFoundation
import ComposableArchitecture
import DomainPermissionInterface
import UIKit

extension PermissionClient: DependencyKey {
    public static var liveValue: PermissionClient {
        PermissionClient(
            status: { permission in
                switch AVCaptureDevice.authorizationStatus(for: permission.avMediaType) {
                case .authorized:
                    return .granted
                case .notDetermined:
                    return .notDetermined
                case .denied, .restricted:
                    // restricted(자녀 보호 등)도 denied 로 접는다 — Interface 주석 참조.
                    return .denied
                @unknown default:
                    return .denied
                }
            },
            request: { permission in
                await AVCaptureDevice.requestAccess(for: permission.avMediaType)
            },
            openSettings: {
                await MainActor.run {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        )
    }
}

private extension MediaPermission {
    /// 마이크도 AVCaptureDevice(.audio) 로 통일 — 영상+음성 캡처 세션 기준의 권한 축 (기존 Example 임시 배선과 동일).
    var avMediaType: AVMediaType {
        switch self {
        case .camera: .video
        case .microphone: .audio
        }
    }
}

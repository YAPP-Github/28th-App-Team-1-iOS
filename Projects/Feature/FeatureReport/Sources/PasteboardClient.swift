//
//  PasteboardClient.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import ComposableArchitecture
import UIKit

/// 시스템 클립보드 seam — 공유 링크 «링크 복사하기» 하나만 쓴다.
/// Feature 안에 둔 이유: 네트워크 Repository 가 아니라 기기 IO 라 Domain 모듈을 새로 세울 근거가 없고,
/// 아직 사용처가 한 곳이다. 두 번째 사용처가 생기면 `SharedCommon` 으로 승격한다.
public struct PasteboardClient: Sendable {
    public var copy: @Sendable (String) -> Void

    public init(copy: @escaping @Sendable (String) -> Void) {
        self.copy = copy
    }
}

extension PasteboardClient: DependencyKey {
    public static var liveValue: PasteboardClient {
        PasteboardClient(copy: { UIPasteboard.general.string = $0 })
    }

    public static var testValue: PasteboardClient {
        PasteboardClient(copy: unimplemented("PasteboardClient.copy"))
    }

    public static var previewValue: PasteboardClient {
        PasteboardClient(copy: { _ in })
    }
}

public extension DependencyValues {
    var pasteboard: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

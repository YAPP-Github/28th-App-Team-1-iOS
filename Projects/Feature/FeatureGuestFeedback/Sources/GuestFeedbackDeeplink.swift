//
//  GuestFeedbackDeeplink.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/07.
//

import Foundation

/// 게스트 평가 공유 딥링크 계약 — `hilit://feedback/{token}`.
/// 형태는 이 Feature 의 소유물이라 파서도 여기 둔다(App 은 호출만).
/// 유니버설 링크(AASA 협의 후)가 생기면 이 파서에 https 형식만 추가한다 — 호출부 불변.
// @lat: [[feedback#진입로와 닫기]]
public enum GuestFeedbackDeeplink {
    /// `hilit://feedback/{token}` → token. 형식이 아니면 nil.
    /// path 세그먼트가 정확히 1개일 때만 통과 — 여분 세그먼트를 무시하면
    /// 미래 형식(`/feedback/{token}/…`)이 생겼을 때 옛 앱이 엉뚱한 토큰으로 진입한다.
    public static func parse(_ url: URL) -> String? {
        guard url.scheme == "hilit", url.host == "feedback" else { return nil }
        let segments = url.pathComponents.filter { $0 != "/" }
        guard segments.count == 1, let token = segments.first, !token.isEmpty else { return nil }
        return token
    }
}

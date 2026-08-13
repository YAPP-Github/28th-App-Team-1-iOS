//
//  GuestFeedbackDeeplink.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/07.
//

import DomainFeedbackShareInterface
import Foundation

/// 게스트 평가 진입 딥링크 계약 — 두 형식을 같은 자리에서 판정한다.
/// 형태는 이 Feature 의 소유물이라 파서도 여기 둔다(App 은 호출만).
///
/// - 유니버설 링크 `https://hilit.chottu.link/report?reportId=…` — 지인에게 실제로 나가는 링크.
///   형식은 `GuestFeedbackShareLink`(조립하는 리포트 쪽과 공유하는 단일 소스)가 안다.
/// - 커스텀 스킴 `hilit://feedback/{token}` — 개발·QA 경로로 존치. 유니버설 링크는 실기기·
///   Associated Domains 가 있어야 도는데 시뮬레이터 검증은 그걸 못 갖춘다.
// @lat: [[feedback#진입로와 닫기]]
public enum GuestFeedbackDeeplink {
    /// 지원하는 두 형식 중 하나면 token, 아니면 nil.
    public static func parse(_ url: URL) -> String? {
        customScheme(url) ?? GuestFeedbackShareLink.token(from: url)
    }

    /// `hilit://feedback/{token}` → token.
    /// path 세그먼트가 정확히 1개일 때만 통과 — 여분 세그먼트를 무시하면
    /// 미래 형식(`/feedback/{token}/…`)이 생겼을 때 옛 앱이 엉뚱한 토큰으로 진입한다.
    private static func customScheme(_ url: URL) -> String? {
        guard url.scheme == "hilit", url.host == "feedback" else { return nil }
        let segments = url.pathComponents.filter { $0 != "/" }
        guard segments.count == 1, let token = segments.first, !token.isEmpty else { return nil }
        return token
    }
}

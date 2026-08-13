//
//  GuestFeedbackShareLink.swift
//  DomainFeedbackShareInterface
//
//  Created by 서정원 on 26/08/13.
//

import Foundation

/// 지인이 열 공유 링크의 형식. **조립(리포트)과 해석(게스트)이 같은 사실을 보도록** 한 곳에 둔다 —
/// 두 Feature 는 서로 의존할 수 없어(D3) 이 계약이 유일한 공유 지점이다. 형식이 갈라지면
/// 만든 링크를 앱이 못 여는 실패가 나는데, 그건 링크를 받은 지인 쪽에서만 드러난다.
///
/// 도메인은 ChottuLink(FDL 대체 SaaS)가 호스팅한다 — 대시보드에 링크 **하나만** 등록해 두고
/// 토큰은 쿼리로 갈아끼운다. 그래서 링크 생성 API 호출이 없고 조립은 문자열뿐이다.
///
/// 세 값 전부 **iOS 단독으로 못 정한다** — 링크를 만드는 쪽과 여는 쪽이 플랫폼을 가리지 않기 때문이다.
/// iOS 가 만든 링크를 Android 사용자가 열고 그 반대도 성립하므로, 한쪽만 바꾸면 그 링크는 반대편에서 죽는다.
/// 현재 값은 팀 합의(2026-08-13 «동적 링크 발급 프로세스»)와 대시보드 실물에 맞춘 것이다.
///
/// - Important: **배포된 링크는 바꿀 수 없다** — 이미 나간 링크가 죽는다. 바꿔야 하면 Android·대시보드와 동시에.
///   entitlement 쪽 도메인 값은 Tuist 매니페스트가 따로 가진다(`Target+Templates.swift` — applinks) — 함께 고친다.
// @lat: [[feedback#진입로와 닫기]]
public enum GuestFeedbackShareLink {
    /// Associated Domains(`applinks:`)에 등록한 링크 도메인.
    public static let host = "hilit.chottu.link"
    /// 지인이 도착하는 경로 — 대시보드에 등록된 링크의 slug 다. 대시보드에 실재하는 링크가 이것뿐이라
    /// 앱이 고를 수 있는 값이 아니다(`/feedback` 은 404). 앱 내부 스킴(`hilit://feedback/…`)과 이름이
    /// 다른 건 그래서다 — 슬러그는 생성 후 변경이 안 돼 만들어진 대로 따라간다.
    public static let path = "/report"
    /// 토큰 쿼리 이름. 값의 실체는 공유 토큰이지 리포트 id 가 아니지만, **이름은 Android 와 맞춘 것**이
    /// 우선이다 — 서버는 이 이름을 모르고 읽는 건 앱뿐이라, 두 플랫폼이 다른 이름을 쓰면 서로가 만든
    /// 링크를 못 연다.
    public static let tokenQueryName = "reportId"

    /// 토큰 → 지인에게 보낼 링크.
    public static func url(token: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = [URLQueryItem(name: tokenQueryName, value: token)]
        // host·path 가 상수고 토큰은 쿼리 값이라 이스케이프가 필요한 문자까지 포함해 항상 조립된다.
        guard let url = components.url else {
            preconditionFailure("공유 링크 조립 실패 — host/path 상수가 깨졌다")
        }
        return url
    }

    /// 링크 → 토큰. 이 형식이 아니면 nil.
    public static func token(from url: URL) -> String? {
        guard url.scheme == "https",
              url.host?.lowercased() == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              normalized(components.path) == path,
              let token = components.queryItems?.first(where: { $0.name == tokenQueryName })?.value,
              !token.isEmpty
        else { return nil }
        return token
    }

    /// 끝의 `/` 만 걷어낸다 — 링크를 중계하는 쪽(SaaS·메신저)이 붙였다 떼는 자리라 형식 판정에서 뺀다.
    private static func normalized(_ path: String) -> String {
        path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}

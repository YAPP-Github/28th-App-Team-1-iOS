//
//  AppEnvironment.swift
//  Hilit
//

import Foundation

/// 앱 실행 계(dev/qa/prod) 판별. 계별 xcconfig 의 `APP_ENV` → Info.plist 로 치환된 값을 읽는다.
/// 환경 인지는 composition root(App)의 책임 — Feature 는 이 값을 State 로 주입받는다. (→ DocC Environments)
enum AppEnvironment {
    /// 현재 빌드가 dev 계인가. (온보딩 dev 전용 진입 게이트 등)
    static var isDev: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String) == "dev"
    }

    /// 마케팅 버전(`CFBundleShortVersionString`, 예 "1.0.0") — 버전 게이트가 서버에 보내는 값.
    /// 키가 없으면 nil 을 돌려 게이트를 건너뛴다 — 임의값("0.0.0")을 보내면 서버가 FORCE 로 답해
    /// 앱이 스스로를 잠근다.
    static var marketingVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

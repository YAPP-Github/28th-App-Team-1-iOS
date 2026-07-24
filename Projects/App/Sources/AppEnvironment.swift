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
}

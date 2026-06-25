//
//  AppConfig.swift
//  AppConfig
//

import ComposableArchitecture
import Foundation

/// 앱 실행 환경(개발계/운영계) 설정값.
///
/// 빌드 Configuration — `Debug`=개발계 / `Release`=운영계 — 에 연결된 xcconfig 가
/// Info.plist 로 치환한 값을 런타임에 읽어 구성한다.
///
/// Feature 는 이 타입을 알 필요가 없다. 환경 분기는 App(composition root)과
/// `*ClientLive` 만의 관심사다.
public struct AppConfig: Sendable, Equatable {
    public enum Environment: String, Sendable {
        case dev
        case qa
        case prod
    }

    public let environment: Environment
    public let baseURL: URL

    public init(environment: Environment, baseURL: URL) {
        self.environment = environment
        self.baseURL = baseURL
    }
}

extension AppConfig {
    /// Info.plist(빌드 시 xcconfig 치환)에서 환경값을 읽어 구성한다.
    /// 키가 없으면(Example 앱·프리뷰 등) 개발계 기본값으로 폴백한다.
    static func fromBundle(_ bundle: Bundle = .main) -> AppConfig {
        let environment = (bundle.object(forInfoDictionaryKey: "APP_ENV") as? String)
            .flatMap(Environment.init(rawValue:)) ?? .dev

        let baseURL = (bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String)
            .flatMap(URL.init(string:)) ?? URL(string: "https://dev-api.architecture.com")!

        return AppConfig(environment: environment, baseURL: baseURL)
    }
}

extension AppConfig: DependencyKey {
    /// 실제 실행 환경 — Info.plist(xcconfig) 기반. 모듈을 link 하면 자동 활성화.
    public static let liveValue = AppConfig.fromBundle()

    /// 프리뷰는 개발계 고정.
    public static let previewValue = AppConfig(
        environment: .dev,
        baseURL: URL(string: "https://dev-api.architecture.com")!
    )

    /// 값 타입이라 호출 가능한 endpoint 가 없다 → `unimplemented` 대상 아님.
    /// 테스트는 명시적 주입을 권장하며, 미주입 시 잡히도록 invalid sentinel 을 둔다.
    public static let testValue = AppConfig(
        environment: .dev,
        baseURL: URL(string: "https://unimplemented.invalid")!
    )
}

extension DependencyValues {
    public var appConfig: AppConfig {
        get { self[AppConfig.self] }
        set { self[AppConfig.self] = newValue }
    }
}

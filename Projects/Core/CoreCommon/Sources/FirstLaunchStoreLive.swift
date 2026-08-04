//
//  FirstLaunchStoreLive.swift
//  CoreCommonImplementation
//
//  Created by EunseoKim on 26/08/03.
//

import ComposableArchitecture
import CoreCommonInterface
import Foundation

// @lat: [[app#첫 실행 정리]]
extension FirstLaunchStore: @retroactive DependencyKey {
    /// 마커는 **UserDefaults** 에 둔다 — 앱 삭제와 함께 사라지는 게 판정의 근거다.
    /// Keychain 에 두면 재설치 후에도 남아 «첫 실행» 을 영원히 놓친다.
    public static var liveValue: FirstLaunchStore { live(suiteName: nil) }

    /// suiteName 주입은 Tests 전용 — 매 호출 UserDefaults 를 새로 열어 Sendable 캡처 문제를 피한다.
    static func live(suiteName: String?) -> FirstLaunchStore {
        let defaults: @Sendable () -> UserDefaults = {
            suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        }
        return FirstLaunchStore(
            isFirstLaunch: { !defaults().bool(forKey: Keys.hasLaunched) },
            markLaunched: { defaults().set(true, forKey: Keys.hasLaunched) }
        )
    }

    private enum Keys {
        static let hasLaunched = "app.hasLaunched"
    }
}

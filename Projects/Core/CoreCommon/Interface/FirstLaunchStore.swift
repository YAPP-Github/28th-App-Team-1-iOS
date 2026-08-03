//
//  FirstLaunchStore.swift
//  CoreCommonInterface
//
//  Created by EunseoKim on 26/08/03.
//

import ComposableArchitecture
import Foundation

// @lat: [[app#첫 실행 정리]]
// «이 설치에서 앱이 한 번이라도 실행됐는가» 하나만 안다.
//
// 앱을 삭제해도 iOS 는 Keychain 을 지우지 않는다 — 재설치하면 옛 토큰만 살아남는다([[api#토큰 수명주기]]).
// 마커를 앱과 함께 사라지는 저장소에 두면 «마커 없음 = 이 설치의 첫 실행» 이 성립하고, 그 자리에서
// 잔존 데이터를 지울 수 있다. 무엇으로 영속하는지는 Implementation 만 안다.
//
// 정리 자체는 여기 없다 — 무엇을 지울지는 조립하는 쪽(AppFeature)의 판단이고, 이 계약은 판정만 맡는다.
public struct FirstLaunchStore: Sendable {
    /// 마커가 없으면 `true`. `markLaunched()` 전까지 몇 번 물어도 같은 답이다.
    public var isFirstLaunch: @Sendable () -> Bool
    /// 마커 기록 — 이후 `isFirstLaunch()` 는 `false`. 잔존 데이터 정리를 **마친 뒤** 호출한다.
    public var markLaunched: @Sendable () -> Void

    public init(
        isFirstLaunch: @escaping @Sendable () -> Bool,
        markLaunched: @escaping @Sendable () -> Void
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.markLaunched = markLaunched
    }
}

public extension FirstLaunchStore {
    /// 인메모리 구현 — Preview·Example·Feature 테스트용. 영속 저장소를 건드리지 않는다.
    static func inMemory(isFirstLaunch: Bool = false) -> FirstLaunchStore {
        let launched = LockIsolated(!isFirstLaunch)
        return FirstLaunchStore(
            isFirstLaunch: { !launched.value },
            markLaunched: { launched.setValue(true) }
        )
    }
}

extension FirstLaunchStore: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지.
    public static var testValue: FirstLaunchStore {
        FirstLaunchStore(
            isFirstLaunch: unimplemented("FirstLaunchStore.isFirstLaunch", placeholder: false),
            markLaunched: unimplemented("FirstLaunchStore.markLaunched")
        )
    }

    /// 프리뷰는 «이미 실행해 본 앱» — 첫 실행 정리가 끼어들지 않는다.
    public static var previewValue: FirstLaunchStore { .inMemory() }
}

public extension DependencyValues {
    var firstLaunchStore: FirstLaunchStore {
        get { self[FirstLaunchStore.self] }
        set { self[FirstLaunchStore.self] = newValue }
    }
}

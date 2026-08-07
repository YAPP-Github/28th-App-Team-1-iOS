//
//  FirstLaunchStoreLiveTests.swift
//  CoreCommonTests
//
//  Created by EunseoKim on 26/08/03.
//

import CoreCommonInterface
import Foundation
import Testing
@testable import CoreCommonImplementation

struct FirstLaunchStoreLiveTests {
    /// 테스트별 격리 suite — 끝나면 지운다. suite 를 새로 만드는 게 «앱 재설치» 를 흉내 내는 방법이다.
    private func withSuite(_ body: (FirstLaunchStore) -> Void) {
        let suiteName = "first-launch-test-\(UUID().uuidString)"
        body(.live(suiteName: suiteName))
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    @Test("마커가 없으면 첫 실행이다")
    func reportsFirstLaunchWhenMarkerIsAbsent() {
        withSuite { store in
            #expect(store.isFirstLaunch())
        }
    }

    @Test("markLaunched 후에는 첫 실행이 아니다")
    func stopsReportingFirstLaunchAfterMark() {
        withSuite { store in
            store.markLaunched()
            #expect(!store.isFirstLaunch())
        }
    }

    @Test("판정은 여러 번 물어도 답이 같다 — 읽기만으로 마커가 생기지 않는다")
    func isFirstLaunchDoesNotMark() {
        withSuite { store in
            #expect(store.isFirstLaunch())
            #expect(store.isFirstLaunch())
        }
    }

    @Test("마커는 suite 밖으로 새지 않는다 — 다른 설치는 다시 첫 실행이다")
    func markerIsScopedToItsInstallation() {
        withSuite { store in
            store.markLaunched()
        }
        withSuite { store in
            #expect(store.isFirstLaunch())
        }
    }
}

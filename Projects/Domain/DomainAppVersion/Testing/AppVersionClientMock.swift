//
//  AppVersionClientMock.swift
//  DomainAppVersionTesting
//
//  Created by EunseoKim on 26/08/01.
//

import DomainAppVersionInterface
import Foundation

public extension AppVersionClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 항상 최신(NONE)을 돌려준다.
    static var mock: AppVersionClient {
        AppVersionClient(
            check: { _ in
                AppVersionPolicy(
                    updateType: .none,
                    latestVersion: "1.0.0",
                    minSupportedVersion: "1.0.0",
                    storeUrl: "https://apps.apple.com/app/id000000000"
                )
            }
        )
    }
}

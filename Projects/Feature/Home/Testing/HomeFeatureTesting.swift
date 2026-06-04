//
//  HomeFeatureTesting.swift
//  HomeFeatureTesting
//
//  Created by EunseoKim on 5/29/26.
//

import Foundation

// MARK: — 다른 모듈의 테스트에서 쓸 mock / fixture
//
// 본 Feature 에서 외부에 공유할 만한 mock 은 아직 없다. State 가 단순해서
// `HomeFeature.State.init()` 그대로 써도 충분. Reducer 가 외부 IO 를 안 가져
// `previewValue` / `testValue` 의존도 없다.
//
// Client / Adapter 가 도입되면 그 모듈의 mock 을 여기에 노출한다. 예:
// `extension UserClient { static let mock = UserClient(fetchUsers: { ... }) }`

public enum HomeFeatureTesting {
    /// 미리 정해둔 인사말이 들어간 State.
    public static func makeWelcomeState() -> HomeFeatureSampleState {
        HomeFeatureSampleState(greeting: "Welcome to Architecture", tapCount: 0)
    }
}

public struct HomeFeatureSampleState: Equatable {
    public let greeting: String
    public let tapCount: Int

    public init(greeting: String, tapCount: Int) {
        self.greeting = greeting
        self.tapCount = tapCount
    }
}

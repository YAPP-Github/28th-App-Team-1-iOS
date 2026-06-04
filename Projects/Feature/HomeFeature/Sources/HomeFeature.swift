//
//  HomeFeature.swift
//  HomeFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import Foundation

/// 탭의 첫 화면. 환영 메시지 + 데모 카운터.
@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var greeting: String
        public var tapCount: Int

        public init(greeting: String = "Hello, Architecture!", tapCount: Int = 0) {
            self.greeting = greeting
            self.tapCount = tapCount
        }
    }

    public enum Action {
        case primaryButtonTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .primaryButtonTapped:
                state.tapCount += 1
                return .none
            }
        }
    }
}

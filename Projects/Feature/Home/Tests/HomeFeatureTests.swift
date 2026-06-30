//
//  HomeFeatureTests.swift
//  HomeFeatureTests
//
//  Created by EunseoKim on 5/29/26.
//

import ComposableArchitecture
import XCTest

@testable import FeatureHome

@MainActor
final class HomeFeatureTests: XCTestCase {
    func test_primaryButtonTapped_increasesTapCount() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.primaryButtonTapped) {
            $0.tapCount = 1
        }

        await store.send(.primaryButtonTapped) {
            $0.tapCount = 2
        }
    }
}

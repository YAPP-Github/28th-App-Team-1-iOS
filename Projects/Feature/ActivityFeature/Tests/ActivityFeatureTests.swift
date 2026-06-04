//
//  ActivityFeatureTests.swift
//  ActivityFeatureTests
//

import ComposableArchitecture
import XCTest

@testable import ActivityFeature

@MainActor
final class ActivityFeatureTests: XCTestCase {
    func test_clearAllTapped_emptiesItems() async {
        let store = TestStore(initialState: ActivityFeature.State()) {
            ActivityFeature()
        }

        await store.send(.clearAllTapped) {
            $0.items = []
        }
    }
}

//
//  ActivityFeatureTests.swift
//  ActivityFeatureTests
//

import ComposableArchitecture
import Models
import XCTest

@testable import ActivityFeature

@MainActor
final class ActivityFeatureTests: XCTestCase {
    func test_onAppear_loadsActivities() async {
        let store = TestStore(initialState: ActivityFeature.State()) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient.fetchActivities = { ActivityItem.samples }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.activitiesLoaded) {
            $0.isLoading = false
            $0.items = ActivityItem.samples
        }
    }

    func test_clearAllTapped_clearsItems() async {
        let store = TestStore(initialState: ActivityFeature.State(items: ActivityItem.samples)) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient.clearAll = {}
        }

        await store.send(.clearAllTapped)
        await store.receive(\.clearedAll) {
            $0.items = []
        }
    }
}

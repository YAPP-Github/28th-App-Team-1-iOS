//
//  ActivityFeatureTests.swift
//  ActivityFeatureTests
//

import DomainActivityInterface
import ComposableArchitecture
import XCTest

import FeatureActivity

@MainActor
final class ActivityFeatureTests: XCTestCase {
    func test_onAppear_loadsActivities() async {
        let items = [ActivityItem(id: 1, title: "Ada followed you", subtitle: "방금 전")]
        let store = TestStore(initialState: ActivityFeature.State()) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient.fetchActivities = { items }
            $0.activityClient.clearAll = unimplemented("clearAll")
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.activitiesLoaded) {
            $0.isLoading = false
            $0.items = items
        }
    }

    func test_clearAllTapped_clearsItems() async {
        let items = [ActivityItem(id: 1, title: "Ada followed you", subtitle: "방금 전")]
        let store = TestStore(initialState: ActivityFeature.State(items: items)) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient.fetchActivities = unimplemented("fetchActivities", placeholder: [])
            $0.activityClient.clearAll = {}
        }

        await store.send(.clearAllTapped)
        await store.receive(\.clearedAll) {
            $0.items = []
        }
    }
}

//
//  NetworkExampleFeatureTests.swift
//  FeatureCommonTests
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import DomainJobInterface
import XCTest
@testable import FeatureCommonImplementation

final class NetworkExampleFeatureTests: XCTestCase {
    @MainActor
    func test_onAppear_성공하면_목록을_채운다() async {
        let store = TestStore(initialState: NetworkExampleFeature.State()) {
            NetworkExampleFeature()
        } withDependencies: {
            $0.jobClient.jobs = { Job.previews }
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
        }
        await store.receive(\.inner.jobsLoaded.success) {
            $0.isLoading = false
            $0.jobs = Job.previews
        }
    }

    @MainActor
    func test_실패하면_에러메시지를_보이고_재시도로_복구한다() async {
        struct FetchError: Error {}
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: NetworkExampleFeature.State()) {
            NetworkExampleFeature()
        } withDependencies: {
            $0.jobClient.jobs = {
                if shouldFail.value {
                    shouldFail.setValue(false)
                    throw FetchError()
                }
                return Job.previews
            }
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
        }
        await store.receive(\.inner.jobsLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "직무 목록을 불러오지 못했어요."
        }

        await store.send(.view(.userTappedRetry)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.inner.jobsLoaded.success) {
            $0.isLoading = false
            $0.jobs = Job.previews
        }
    }
}

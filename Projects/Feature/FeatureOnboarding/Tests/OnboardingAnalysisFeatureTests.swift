//
//  OnboardingAnalysisFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingAnalysisFeatureTests {
    private let data = OnboardingData(userName: "재원", jobRole: "BACKEND")

    @Test("진입 시 분석을 시작하고, 분석·완료 홀드가 끝나면 온보딩 완료를 delegate 로 올린다")
    func analysisFlowCompletesAndDelegates() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: data)) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.onAppear)) {
            $0.hasStartedAnalysis = true
        }

        await clock.advance(by: OnboardingAnalysisFeature.analysisDuration)
        await store.receive(\.inner.analysisCompleted) {
            $0.phase = .completed
        }

        await clock.advance(by: OnboardingAnalysisFeature.completionHoldDuration)
        await store.receive(\.inner.completionHoldFinished)
        await store.receive(\.delegate.completed)
    }

    @Test("onAppear 재진입은 분석을 중복 시작하지 않는다")
    func onAppearIsIdempotent() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: data)) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.onAppear)) {
            $0.hasStartedAnalysis = true
        }
        // 두 번째 onAppear 는 상태 변화도, 새 effect 도 없어야 한다 —
        // 중복 시작됐다면 아래에서 analysisCompleted 를 두 번 받아 테스트가 실패한다.
        await store.send(.view(.onAppear))

        await clock.advance(by: OnboardingAnalysisFeature.analysisDuration)
        await store.receive(\.inner.analysisCompleted) {
            $0.phase = .completed
        }

        await clock.advance(by: OnboardingAnalysisFeature.completionHoldDuration)
        await store.receive(\.inner.completionHoldFinished)
        await store.receive(\.delegate.completed)
    }

    @Test("분석 중 닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: data)) {
            OnboardingAnalysisFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }

    @Test("주입된 OnboardingData 를 상태로 보존한다")
    func keepsInjectedOnboardingData() async {
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: data)) {
            OnboardingAnalysisFeature()
        }

        #expect(store.state.data == data)
        #expect(store.state.phase == .analyzing)
    }
}

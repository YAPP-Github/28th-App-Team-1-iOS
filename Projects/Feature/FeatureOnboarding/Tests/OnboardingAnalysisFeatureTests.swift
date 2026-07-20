//
//  OnboardingAnalysisFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import DomainInterviewInterface
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingAnalysisFeatureTests {
    private static let portfolioId = UUID(uuidString: "00000000-0000-0000-0000-0000000000f1")!

    /// 세션 입력을 만들 수 있는 완전한 수집 데이터(직군·연차·포트폴리오 필수).
    private func fullData() -> OnboardingData {
        OnboardingData(
            userName: "재원",
            jobRole: "BACKEND",
            career: .overOneYear,
            portfolioId: Self.portfolioId
        )
    }

    @Test("진입 시 세션을 생성하고 READY 폴링 후 세션 id 를 delegate 로 올린다")
    func analysisCreatesSessionAndCompletes() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: fullData())) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient.createSession = { _ in
                InterviewSessionCreated(sessionId: 7, status: "PROCESSING", statusUrl: nil)
            }
            $0.interviewClient.sessionStatus = { _ in
                InterviewSessionStatus(status: .ready, startedAt: nil, summaryQuestion: nil)
            }
        }

        await store.send(.view(.onAppear)) { $0.hasStartedAnalysis = true }
        await store.receive(\.inner.sessionCreated) { $0.sessionId = 7 }
        await store.receive(\.inner.statusPolled) { $0.phase = .completed }
        await clock.advance(by: OnboardingAnalysisFeature.completionHoldDuration)
        await store.receive(\.inner.completionHoldFinished)
        await store.receive(\.delegate.completed, 7)
    }

    @Test("PROCESSING 응답은 폴링 간격 뒤 재조회해 READY 로 완료된다")
    func analysisPollsUntilReady() async {
        let clock = TestClock()
        let statusCalls = LockIsolated(0)
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: fullData())) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient.createSession = { _ in
                InterviewSessionCreated(sessionId: 7, status: "PROCESSING", statusUrl: nil)
            }
            $0.interviewClient.sessionStatus = { _ in
                statusCalls.withValue { $0 += 1 }
                let ready = statusCalls.value > 1
                return InterviewSessionStatus(status: ready ? .ready : .processing, startedAt: nil, summaryQuestion: nil)
            }
        }

        await store.send(.view(.onAppear)) { $0.hasStartedAnalysis = true }
        await store.receive(\.inner.sessionCreated) { $0.sessionId = 7 }
        await store.receive(\.inner.statusPolled)   // 1회차 PROCESSING — 상태 변화 없음
        await clock.advance(by: OnboardingAnalysisFeature.pollInterval)
        await store.receive(\.inner.statusPolled) { $0.phase = .completed }
        await clock.advance(by: OnboardingAnalysisFeature.completionHoldDuration)
        await store.receive(\.inner.completionHoldFinished)
        await store.receive(\.delegate.completed, 7)
    }

    @Test("세션 생성 실패는 실패 화면으로 전환한다 (재시도 없음)")
    func analysisFailsOnCreateError() async {
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: fullData())) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.interviewClient.createSession = { _ in throw NSError(domain: "test", code: -1) }
        }

        await store.send(.view(.onAppear)) { $0.hasStartedAnalysis = true }
        await store.receive(\.inner.analysisFailed) {
            $0.phase = .failed(message: OnboardingAnalysisFeature.failureMessage)
        }
    }

    @Test("수집 데이터가 불완전하면 세션 생성 없이 실패한다")
    func analysisFailsWhenConfigIncomplete() async {
        // career·portfolioId 누락 → interviewConfig() 가 nil → createSession 호출 안 됨.
        let store = TestStore(
            initialState: OnboardingAnalysisFeature.State(data: OnboardingData(userName: "재원", jobRole: "BACKEND"))
        ) {
            OnboardingAnalysisFeature()
        }

        await store.send(.view(.onAppear)) { $0.hasStartedAnalysis = true }
        await store.receive(\.inner.analysisFailed) {
            $0.phase = .failed(message: OnboardingAnalysisFeature.configMissingMessage)
        }
    }

    @Test("onAppear 재진입은 세션 생성을 중복하지 않는다")
    func onAppearIsIdempotent() async {
        let clock = TestClock()
        let createCalls = LockIsolated(0)
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: fullData())) {
            OnboardingAnalysisFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient.createSession = { _ in
                createCalls.withValue { $0 += 1 }
                return InterviewSessionCreated(sessionId: 7, status: "PROCESSING", statusUrl: nil)
            }
            $0.interviewClient.sessionStatus = { _ in
                InterviewSessionStatus(status: .ready, startedAt: nil, summaryQuestion: nil)
            }
        }

        await store.send(.view(.onAppear)) { $0.hasStartedAnalysis = true }
        await store.receive(\.inner.sessionCreated) { $0.sessionId = 7 }
        await store.receive(\.inner.statusPolled) { $0.phase = .completed }
        // 완료 홀드 중 재진입 — 이미 시작됐으므로 상태 변화도, 새 세션 생성도 없어야 한다.
        await store.send(.view(.onAppear))
        await clock.advance(by: OnboardingAnalysisFeature.completionHoldDuration)
        await store.receive(\.inner.completionHoldFinished)
        await store.receive(\.delegate.completed, 7)
        #expect(createCalls.value == 1)
    }

    @Test("분석 중 닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: fullData())) {
            OnboardingAnalysisFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }

    @Test("주입된 OnboardingData 를 상태로 보존한다")
    func keepsInjectedOnboardingData() async {
        let data = fullData()
        let store = TestStore(initialState: OnboardingAnalysisFeature.State(data: data)) {
            OnboardingAnalysisFeature()
        }

        #expect(store.state.data == data)
        #expect(store.state.phase == .analyzing)
    }
}

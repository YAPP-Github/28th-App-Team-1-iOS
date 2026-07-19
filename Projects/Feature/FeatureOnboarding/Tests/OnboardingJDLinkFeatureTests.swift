//
//  OnboardingJDLinkFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import DomainJDInterface
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingJDLinkFeatureTests {
    private let link = "https://recruit.hilit.dev/jobs/123"

    @Test("링크 입력 후 디바운스가 지나면 검증을 시작하고 성공을 반영한다")
    func linkTypingDebouncesThenValidates() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.jdClient.validate = { _ in JDValidation(valid: true, reason: nil, message: nil) }
        }

        await store.send(\.view.binding.linkText, link) {
            $0.linkText = self.link
        }
        await clock.advance(by: OnboardingJDLinkFeature.validationDebounce)
        await store.receive(\.inner.validationStarted) {
            $0.linkValidation = .loading
        }
        await store.receive(\.inner.linkValidated) {
            $0.linkValidation = .success
        }
    }

    @Test("입력이 이어지면 이전 디바운스 예약을 취소하고 마지막 값만 검증한다")
    func retypingCancelsPendingValidation() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.jdClient.validate = { [link] url in
                // 마지막 입력만 검증돼야 한다 — 이전 예약이 살아 있으면 여기서 잡힌다.
                #expect(url == link)
                return JDValidation(valid: true, reason: nil, message: nil)
            }
        }

        await store.send(\.view.binding.linkText, "https://a") {
            $0.linkText = "https://a"
        }
        await clock.advance(by: .milliseconds(300))
        await store.send(\.view.binding.linkText, link) {
            $0.linkText = self.link
        }
        await clock.advance(by: OnboardingJDLinkFeature.validationDebounce)
        await store.receive(\.inner.validationStarted) {
            $0.linkValidation = .loading
        }
        await store.receive(\.inner.linkValidated) {
            $0.linkValidation = .success
        }
    }

    @Test("링크를 비우면 검증 예약 없이 대기 상태로 돌아간다")
    func emptyingLinkReturnsToIdle() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        initialState.linkValidation = .failure(message: "x")
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(\.view.binding.linkText, "") {
            $0.linkText = ""
            $0.linkValidation = .idle
        }
    }

    @Test("서버가 유효하지 않다고 응답하면 서버 메시지로 에러 상태가 된다")
    func invalidLinkShowsServerMessage() async {
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.jdClient.validate = { _ in
                JDValidation(valid: false, reason: "CRAWLING_FAILED", message: "크롤링에 실패했어요.")
            }
        }

        await store.send(\.view.binding.linkText, link) {
            $0.linkText = self.link
        }
        await store.receive(\.inner.validationStarted) {
            $0.linkValidation = .loading
        }
        await store.receive(\.inner.linkValidated) {
            $0.linkValidation = .failure(message: "크롤링에 실패했어요.")
        }
    }

    @Test("검증 네트워크 오류는 기본 문구의 에러 상태가 된다")
    func validationNetworkFailureShowsFallbackMessage() async {
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.jdClient.validate = { _ in throw NSError(domain: "test", code: -1) }
        }

        await store.send(\.view.binding.linkText, link) {
            $0.linkText = self.link
        }
        await store.receive(\.inner.validationStarted) {
            $0.linkValidation = .loading
        }
        await store.receive(\.inner.linkValidationFailed) {
            $0.linkValidation = .failure(message: OnboardingJDLinkFeature.fallbackErrorMessage)
        }
    }

    @Test("키보드 제출은 디바운스 없이 즉시 검증을 시작한다")
    func submitValidatesImmediately() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        } withDependencies: {
            $0.jdClient.validate = { _ in JDValidation(valid: true, reason: nil, message: nil) }
        }

        await store.send(.view(.userSubmittedLink))
        await store.receive(\.inner.validationStarted) {
            $0.linkValidation = .loading
        }
        await store.receive(\.inner.linkValidated) {
            $0.linkValidation = .success
        }
    }

    @Test("링크 클리어는 입력과 검증 상태를 초기화한다")
    func clearLinkResetsValidation() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        initialState.linkValidation = .failure(message: "x")
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedClearLink)) {
            $0.linkText = ""
            $0.linkValidation = .idle
        }
    }

    @Test("검증 성공 상태의 계속하기는 링크 페이로드를 delegate 로 올린다")
    func continueWithValidatedLinkEmitsLinkPayload() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        initialState.linkValidation = .success
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, .link(link))
    }

    @Test("미검증 링크의 계속하기는 스킵(nil)으로 올린다")
    func continueWithUnvalidatedLinkSkips() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, nil)
    }

    @Test("분석 중에는 계속하기를 무시한다")
    func continueIsIgnoredWhileLoading() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        initialState.linkValidation = .loading
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedContinue))
    }

    @Test("직접 입력 텍스트의 계속하기는 text 페이로드로 올린다")
    func continueWithDirectTextEmitsTextPayload() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.mode = .directText
        initialState.directText = "백엔드 개발자 채용. 자격 요건: Kotlin, Spring…"
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(
            \.delegate.continueRequested,
            .text("백엔드 개발자 채용. 자격 요건: Kotlin, Spring…")
        )
    }

    @Test("직접 입력이 비어 있으면 계속하기는 스킵(nil)으로 올린다")
    func continueWithEmptyDirectTextSkips() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.mode = .directText
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, nil)
    }

    @Test("탭 전환은 입력 모드를 바꾼다")
    func selectingModeSwitchesTab() async {
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userSelectedMode(.directText))) {
            $0.mode = .directText
        }
        await store.send(.view(.userSelectedMode(.link))) {
            $0.mode = .link
        }
    }

    @Test("검증 성공 후에는 직접 입력 탭 전환이 막힌다")
    func directTextTabIsDisabledAfterSuccess() async {
        var initialState = OnboardingJDLinkFeature.State()
        initialState.linkText = link
        initialState.linkValidation = .success
        let store = TestStore(initialState: initialState) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userSelectedMode(.directText)))
    }

    @Test("이전으로 탭은 delegate 로 코디네이터에 위임한다")
    func backDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
    }

    @Test("닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }
}

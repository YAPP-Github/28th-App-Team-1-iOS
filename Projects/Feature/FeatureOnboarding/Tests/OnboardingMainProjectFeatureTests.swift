//
//  OnboardingMainProjectFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingMainProjectFeatureTests {
    @Test("텍스트 바인딩이 상태에 반영된다")
    func bindingUpdatesText() async {
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.binding(.set(\.projectDescription, "결제 시스템 리팩토링")))) {
            $0.projectDescription = "결제 시스템 리팩토링"
        }
    }

    @Test("입력은 300자 상한으로 잘린다")
    func bindingClampsToMaxLength() async {
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        }

        let overflow = String(repeating: "가", count: 301)
        await store.send(.view(.binding(.set(\.projectDescription, overflow)))) {
            $0.projectDescription = String(repeating: "가", count: 300)
        }
    }

    @Test("건너뛰기는 입력이 있어도 버리고 nil 로 올린다")
    func skipDiscardsInput() async {
        var initialState = OnboardingMainProjectFeature.State()
        initialState.projectDescription = "짧음"   // 하한 미달 — 스킵은 선검증을 타지 않는다.
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedSkip))
        await store.receive(\.delegate.continueRequested, nil)
    }

    @Test("계속하기는 앞뒤 공백을 제거한 입력값을 delegate 로 올린다")
    func continueEmitsTrimmedFreeText() async {
        var initialState = OnboardingMainProjectFeature.State()
        initialState.projectDescription = "  결제 시스템 리팩토링, Redis 캐시 도입  "
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, "결제 시스템 리팩토링, Redis 캐시 도입")
    }

    @Test("빈 입력의 계속하기는 nil(건너뜀)로 올린다 — 선택 스텝이라 항상 진행 가능")
    func continueWithEmptyTextEmitsNil() async {
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, String?.none)
    }

    @Test("공백만 있는 입력도 건너뜀(nil)으로 처리한다")
    func continueWithWhitespaceOnlyEmitsNil() async {
        var initialState = OnboardingMainProjectFeature.State()
        initialState.projectDescription = "   "
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, String?.none)
    }

    @Test("입력이 1~9자면 계속하기를 막고 하한 경고를 노출한다")
    func continueBelowMinLengthShowsWarning() async {
        var initialState = OnboardingMainProjectFeature.State()
        initialState.projectDescription = "짧은글"   // 3자 — 하한 10자 미달
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        // delegate 방출 없이 경고만 세팅된다 (서버 왕복 차단).
        await store.send(.view(.userTappedContinue)) {
            $0.inputWarning = OnboardingMainProjectFeature.lengthWarningMessage
        }
    }

    @Test("입력이 정확히 10자면 계속하기가 통과한다 (하한 경계)")
    func continueAtMinLengthEmits() async {
        var initialState = OnboardingMainProjectFeature.State()
        let text = String(repeating: "가", count: 10)
        initialState.projectDescription = text
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, text)
    }

    @Test("하한 경고는 편집(입력)하면 사라진다")
    func editClearsLengthWarning() async {
        var initialState = OnboardingMainProjectFeature.State()
        initialState.projectDescription = "짧은글"
        initialState.inputWarning = OnboardingMainProjectFeature.lengthWarningMessage
        let store = TestStore(initialState: initialState) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.binding(.set(\.projectDescription, "짧은글자수정")))) {
            $0.projectDescription = "짧은글자수정"
            $0.inputWarning = nil
        }
    }

    @Test("이전으로 탭은 delegate 로 코디네이터에 위임한다")
    func backDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
    }

    @Test("닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }

    @Test("스킵 툴팁은 onAppear 후 3초가 지나면 사라진다")
    func tooltipExpiresAfterDelay() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingMainProjectFeature.State()) {
            OnboardingMainProjectFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        #expect(store.state.showsSkipTooltip)   // 진입 직후엔 노출.
        await store.send(.view(.onAppear))
        await clock.advance(by: OnboardingMainProjectFeature.tooltipDuration)
        await store.receive(\.inner.tooltipExpired) {
            $0.isTooltipExpired = true
        }
        #expect(!store.state.showsSkipTooltip)   // 3초 뒤 사라짐.
    }
}

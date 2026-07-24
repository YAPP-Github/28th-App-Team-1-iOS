//
//  OnboardingFocusProjectFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingFocusProjectFeatureTests {
    @Test("텍스트 바인딩이 상태에 반영된다")
    func bindingUpdatesText() async {
        let store = TestStore(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.binding(.set(\.projectDescription, "결제 시스템 리팩토링")))) {
            $0.projectDescription = "결제 시스템 리팩토링"
        }
    }

    @Test("입력은 300자 상한으로 잘린다")
    func bindingClampsToMaxLength() async {
        let store = TestStore(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }

        let overflow = String(repeating: "가", count: 301)
        await store.send(.view(.binding(.set(\.projectDescription, overflow)))) {
            $0.projectDescription = String(repeating: "가", count: 300)
        }
    }

    @Test("클리어 버튼은 입력을 비운다")
    func clearEmptiesText() async {
        var initialState = OnboardingFocusProjectFeature.State()
        initialState.projectDescription = "결제 시스템 리팩토링"
        let store = TestStore(initialState: initialState) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedClearText)) {
            $0.projectDescription = ""
        }
    }

    @Test("계속하기는 앞뒤 공백을 제거한 입력값을 delegate 로 올린다")
    func continueEmitsTrimmedFreeText() async {
        var initialState = OnboardingFocusProjectFeature.State()
        initialState.projectDescription = "  결제 시스템 리팩토링, Redis 캐시 도입  "
        let store = TestStore(initialState: initialState) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, "결제 시스템 리팩토링, Redis 캐시 도입")
    }

    @Test("빈 입력의 계속하기는 nil(건너뜀)로 올린다 — 선택 스텝이라 항상 진행 가능")
    func continueWithEmptyTextEmitsNil() async {
        let store = TestStore(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, String?.none)
    }

    @Test("공백만 있는 입력도 건너뜀(nil)으로 처리한다")
    func continueWithWhitespaceOnlyEmitsNil() async {
        var initialState = OnboardingFocusProjectFeature.State()
        initialState.projectDescription = "   "
        let store = TestStore(initialState: initialState) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, String?.none)
    }

    @Test("이전으로 탭은 delegate 로 코디네이터에 위임한다")
    func backDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
    }

    @Test("닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }

    @Test("클리어 버튼은 입력이 있을 때만 노출된다")
    func clearButtonVisibility() {
        var state = OnboardingFocusProjectFeature.State()
        #expect(!state.isClearButtonVisible)

        state.projectDescription = "가"
        #expect(state.isClearButtonVisible)
    }

    @Test("카운터 라벨은 «글자수/300자» 형식이다")
    func characterCountLabelFormat() {
        var state = OnboardingFocusProjectFeature.State()
        #expect(state.characterCountLabel == "0/300자")

        state.projectDescription = "가나다"
        #expect(state.characterCountLabel == "3/300자")
    }
}

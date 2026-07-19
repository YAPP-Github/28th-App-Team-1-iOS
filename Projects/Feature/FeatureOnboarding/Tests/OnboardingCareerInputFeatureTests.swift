//
//  OnboardingCareerInputFeatureTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingCareerInputFeatureTests {
    @Test("초기 상태는 첫 선택지(신입)와 전체 선택지 목록을 갖는다")
    func initialStateDefaultsToNewcomer() {
        let state = OnboardingCareerInputFeature.State()

        #expect(state.selectedCareer == .newcomer)
        #expect(state.options == CareerOption.allCases)
    }

    @Test("휠 선택은 선택 연차를 갱신한다")
    func selectingCareerUpdatesState() async {
        let store = TestStore(initialState: OnboardingCareerInputFeature.State()) {
            OnboardingCareerInputFeature()
        }

        await store.send(.view(.userSelectedCareer(.overOneYear))) {
            $0.selectedCareer = .overOneYear
        }
    }

    @Test("계속하기는 선택 연차를 delegate 로 올린다")
    func continueEmitsSelectedCareer() async {
        let store = TestStore(
            initialState: OnboardingCareerInputFeature.State(selectedCareer: .overTwoYears)
        ) {
            OnboardingCareerInputFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, .overTwoYears)
    }

    @Test("이전으로 탭은 delegate 로 코디네이터에 위임한다")
    func backDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingCareerInputFeature.State()) {
            OnboardingCareerInputFeature()
        }

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
    }

    @Test("닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingCareerInputFeature.State()) {
            OnboardingCareerInputFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }
}

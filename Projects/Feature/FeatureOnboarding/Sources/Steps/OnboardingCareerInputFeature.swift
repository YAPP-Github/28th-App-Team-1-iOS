//
//  OnboardingCareerInputFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture

/// 온보딩 STEP 2 연차 선택지 — Figma «STEP 2_연차» 휠 목록 원문 순서.
/// 서버 연차 enum 이 아직 없어 rawValue 는 임시 식별자다.
// TODO: API 연결 — 서버 연차 enum 확정 시 rawValue·케이스 목록 정합 확인.
public enum CareerOption: String, CaseIterable, Sendable {
    case newcomer = "NEWCOMER"
    case underSixMonths = "UNDER_6_MONTHS"
    case overOneYear = "OVER_1_YEAR"
    case overTwoYears = "OVER_2_YEARS"
    case overThreeYears = "OVER_3_YEARS"

    /// 화면 표기 라벨 (Figma 원문).
    public var label: String {
        switch self {
        case .newcomer: "신입"
        case .underSixMonths: "6개월 이하"
        case .overOneYear: "1년 이상"
        case .overTwoYears: "2년 이상"
        case .overThreeYears: "3년 이상"
        }
    }
}

// @lat: [[onboarding#연차 입력]]
/// 온보딩 STEP 2 — 연차 입력. 문장형 휠("내 경력은 [연차] 이다.")로 연차를 고른다.
/// 휠 특성상 항상 선택값이 있어 CTA 는 항상 활성이고,
/// 완료·뒤로·닫기는 delegate 로 코디네이터(OnboardingFeature)에 올린다.
@Reducer
public struct OnboardingCareerInputFeature {
    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 휠 선택지 — 디자인 고정 목록 (외부 IO 없음).
        public let options: [CareerOption]
        /// 휠 중앙에 놓인 현재 선택.
        public var selectedCareer: CareerOption

        public init(
            step: Int = 2,
            totalSteps: Int = 5,
            selectedCareer: CareerOption = .newcomer
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.options = CareerOption.allCases
            self.selectedCareer = selectedCareer
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            /// 휠 스냅이 멈춰 중앙 행이 바뀌었다.
            case userSelectedCareer(CareerOption)
            case userTappedBack
            case userTappedClose
            case userTappedContinue
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 연차 선택 완료 — 다음 스텝으로.
            case continueRequested(career: CareerOption)
            /// 뒤로(하단 «이전으로») — 코디네이터가 스택을 pop.
            case backRequested
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.userSelectedCareer(option)):
                state.selectedCareer = option
                return .none

            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .view(.userTappedContinue):
                return .send(.delegate(.continueRequested(career: state.selectedCareer)))

            case .delegate:
                return .none
            }
        }
    }
}

//
//  OnboardingCareerInputFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture

/// 온보딩 STEP 2 연차 선택지 — 정수 연차(0~10년, 10 = "10년 이상"). PRD S0 정수 드롭다운.
/// `years` 가 그대로 서버 세션 입력(`InterviewConfig.careerYears`)이 된다.
public struct CareerOption: Hashable, Sendable, Identifiable {
    /// 상한 — 10 은 "10년 이상"을 뜻한다.
    public static let maxYears = 10
    /// 휠에 나열되는 전체 선택지 (0~10년).
    public static let all: [CareerOption] = (0...maxYears).map(CareerOption.init)

    public let years: Int
    public var id: Int { years }

    /// 문장형 휠 라벨 — «내 경력은 [label] 이다.»
    public var label: String {
        switch years {
        case 0: "신입"
        case Self.maxYears: "\(Self.maxYears)년 이상"
        default: "\(years)년차"
        }
    }

    public init(years: Int) {
        self.years = years
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
        /// 휠 선택지 — 0~10년 정수 목록 (외부 IO 없음).
        public let options: [CareerOption]
        /// 휠 중앙에 놓인 현재 선택.
        public var selectedCareer: CareerOption

        public init(
            step: Int = 2,
            totalSteps: Int = 5,
            selectedCareer: CareerOption = CareerOption(years: 0)
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.options = CareerOption.all
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
            /// 연차 선택 완료 — 정수 연차(년)를 올린다. 그대로 `InterviewConfig.careerYears`.
            case continueRequested(careerYears: Int)
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
                return .send(.delegate(.continueRequested(careerYears: state.selectedCareer.years)))

            case .delegate:
                return .none
            }
        }
    }
}

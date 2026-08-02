//
//  AuthOnboardingExperienceFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

/// 연차 선택지 — 정수 연차(0~10년, 10 = "10년 이상").
/// FeatureOnboarding `CareerOption` 의 복제본 — 가입·면접 위저드가 같은 선택지를 쓰지만
/// Feature 간 코드 공유가 금지라 복사(원본 [[onboarding#연차 입력]], 위저드 정리 시 원본 제거 예정).
public struct ExperienceOption: Hashable, Sendable, Identifiable {
    /// 상한 — 10 은 "10년 이상"을 뜻한다.
    public static let maxYears = 10
    /// 휠에 나열되는 전체 선택지 (0~10년).
    public static let all: [ExperienceOption] = (0...maxYears).map(ExperienceOption.init)

    public let years: Int
    public var id: Int { years }

    /// 문장형 휠 라벨 — «내 경력은 [label] 이다» (Figma 3632:14460 의 휠 표기).
    public var label: String {
        switch years {
        case 0: "신입"
        default: "\(years)년 이상"
        }
    }

    public init(years: Int) {
        self.years = years
    }
}

// @lat: [[auth#가입 플로우]]
/// 가입 온보딩 3 — 연차 선택. FeatureOnboarding STEP2(OnboardingCareerInputFeature)의 복사본.
/// 문장형 휠("내 경력은 [연차] 이다.")로 연차를 고른다 — 휠 특성상 항상 선택값이 있어 CTA 상시 활성.
@Reducer
public struct AuthOnboardingExperienceFeature {
    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 가입 온보딩 수집 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 휠 선택지 — 0~10년 정수 목록 (외부 IO 없음).
        public let options: [ExperienceOption]
        /// 휠 중앙에 놓인 현재 선택.
        public var selectedExperience: ExperienceOption

        public init(
            step: Int = 3,
            totalSteps: Int = 3,
            selectedExperience: ExperienceOption = ExperienceOption(years: 0)
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.options = ExperienceOption.all
            self.selectedExperience = selectedExperience
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            /// 휠 스냅이 멈춰 중앙 행이 바뀌었다.
            case userSelectedExperience(ExperienceOption)
            case userTappedBack
            case userTappedClose
            case userTappedContinue
        }

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 연차 선택 완료 — 정수 연차(년)를 올린다. 이걸 받은 코디네이터가 이름·직군과 묶어
            /// 프로필을 PATCH 하고, 성공해야 등록 완료로 넘어간다(실패 알럿도 코디네이터 몫).
            case continueRequested(careerYears: Int)
            /// 뒤로(하단 «이전으로») — 코디네이터가 스택을 pop.
            case backRequested
            /// 가입 온보딩 이탈(X) — 처리는 코디네이터 몫.
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.userSelectedExperience(option)):
                state.selectedExperience = option
                return .none

            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .view(.userTappedContinue):
                return .send(.delegate(.continueRequested(careerYears: state.selectedExperience.years)))

            case .delegate:
                return .none
            }
        }
    }
}

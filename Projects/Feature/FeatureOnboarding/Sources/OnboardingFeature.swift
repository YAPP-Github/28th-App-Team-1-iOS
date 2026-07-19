//
//  OnboardingFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture

// @lat: [[onboarding#코디네이터]]
/// 온보딩 위저드 코디네이터. STEP 1(직군 선택)을 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다.
/// 각 스텝의 delegate 만 매칭해 공유 데이터(OnboardingData)를 누적하고 다음 스텝으로 전환한다 (D5).
/// 스텝 자체 간 직접 의존은 없다 — 조립은 여기서만 (도메인 내 navigation = Path/StackState).
@Reducer
public struct OnboardingFeature {
    /// 위저드 총 스텝 수 — 모든 스텝 디자인의 프로그레스 바가 5칸 (분석 화면은 프로그레스 밖).
    public static let totalSteps = 5

    @Reducer
    public enum Path {
        case careerInput(OnboardingCareerInputFeature)      // STEP 2 연차
        case jdLink(OnboardingJDLinkFeature)                // STEP 3 JD 링크(스킵 가능)
        case portfolioUpload(OnboardingPortfolioUploadFeature) // STEP 4 포트폴리오
        case focusProject(OnboardingFocusProjectFeature)    // STEP 5 집중 프로젝트(선택)
        case analysis(OnboardingAnalysisFeature)            // 분석 — 수집 데이터 제출·완료 전환
    }

    // @Reducer enum 이 생성하는 Path.State 는 Equatable 을 자동 채택하지 않는다 —
    // StackState<Path.State> 를 담는 코디네이터 State 의 Equatable 합성을 위해 명시한다.

    @ObservableState
    public struct State: Equatable {
        /// STEP 1 — 루트 화면(직군 선택).
        public var jobSelection: OnboardingJobSelectionFeature.State
        /// STEP 2+ 네비게이션 스택.
        public var path = StackState<Path.State>()
        /// 스텝을 거치며 누적되는 공유 페이로드.
        public var data: OnboardingData

        public init(userName: String = "") {
            self.data = OnboardingData(userName: userName)
            self.jobSelection = OnboardingJobSelectionFeature.State(
                userName: userName,
                step: 1,
                totalSteps: OnboardingFeature.totalSteps
            )
        }
    }

    public enum Action {
        case jobSelection(OnboardingJobSelectionFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 중도 이탈(X) — dismiss 는 부모(AppFeature)가 처리한다.
            case dismiss
            /// 온보딩 완료(분석까지 끝) — 부모가 메인 진입 등으로 전환한다.
            case finished
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.jobSelection, action: \.jobSelection) {
            OnboardingJobSelectionFeature()
        }

        Reduce { state, action in
            switch action {
            // STEP 1 완료 → 직군 저장 후 연차 입력 push.
            case let .jobSelection(.delegate(.continueRequested(jobRole))):
                state.data.jobRole = jobRole
                state.path.append(.careerInput(.init(step: 2, totalSteps: Self.totalSteps)))
                return .none

            case .jobSelection(.delegate(.closeRequested)):
                return .send(.delegate(.dismiss))

            case .jobSelection:
                return .none

            // STEP 2 연차 → JD 링크 push.
            case let .path(.element(id: _, action: .careerInput(.delegate(action)))):
                switch action {
                case let .continueRequested(career):
                    state.data.career = career
                    state.path.append(.jdLink(.init(step: 3, totalSteps: Self.totalSteps)))
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            // STEP 3 JD 링크(nil = 스킵) → 포트폴리오 push.
            case let .path(.element(id: _, action: .jdLink(.delegate(action)))):
                switch action {
                case let .continueRequested(submission):
                    switch submission {
                    case let .link(url):
                        state.data.jdLink = url
                        state.data.jdText = nil
                    case let .text(text):
                        state.data.jdText = text
                        state.data.jdLink = nil
                    case nil:
                        state.data.jdLink = nil
                        state.data.jdText = nil
                    }
                    state.path.append(.portfolioUpload(.init(step: 4, totalSteps: Self.totalSteps)))
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            // STEP 4 포트폴리오 → 집중 프로젝트 push.
            case let .path(.element(id: _, action: .portfolioUpload(.delegate(action)))):
                switch action {
                case let .continueRequested(portfolioId):
                    state.data.portfolioId = portfolioId
                    state.path.append(.focusProject(.init(step: 5, totalSteps: Self.totalSteps)))
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            // STEP 5 집중 프로젝트(마지막 수집 스텝) → 누적 데이터를 들고 분석 push.
            case let .path(.element(id: _, action: .focusProject(.delegate(action)))):
                switch action {
                case let .continueRequested(freeText):
                    state.data.freeText = freeText
                    state.path.append(.analysis(.init(data: state.data)))
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            // 분석 — 완료(자동 전환)면 위저드 종료, X 면 이탈.
            case let .path(.element(id: _, action: .analysis(.delegate(action)))):
                switch action {
                case .completed:
                    return .send(.delegate(.finished))
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// Path.State(=@Reducer enum 생성물)에 Equatable 합성 — 모든 스텝 State 가 Equatable 이므로 성립.
extension OnboardingFeature.Path.State: Equatable {}

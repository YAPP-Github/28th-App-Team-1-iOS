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

    /// 연관성 4회 실패 시 제시하는 두 선택지 — PRD S3.5.
    public static let relevanceFailureLimit = 4
    /// 연관성 실패(4회 미만) 시 집중 프로젝트에 노출하는 경고 (PRD 확정 문구).
    static let relevanceWarningMessage = "포트폴리오에서 그 내용을 찾지 못했어요.\n포트폴리오에 있는 프로젝트로 다시 적어주세요."

    @ObservableState
    public struct State: Equatable {
        /// STEP 1 — 루트 화면(직군 선택).
        public var jobSelection: OnboardingJobSelectionFeature.State
        /// STEP 2+ 네비게이션 스택.
        public var path = StackState<Path.State>()
        /// 스텝을 거치며 누적되는 공유 페이로드.
        public var data: OnboardingData
        /// 집중 프로젝트 연관성 연속 실패 횟수 — PRD S3.5 (4회째 두 선택지 제시).
        public var relevanceFailureCount = 0
        /// 4회째 연관성 실패 시 뜨는 선택지 다이얼로그.
        @Presents public var relevanceChoice: ConfirmationDialogState<Action.RelevanceChoice>?

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
        case relevanceChoice(PresentationAction<RelevanceChoice>)
        case delegate(Delegate)

        /// 연관성 4회 실패 다이얼로그의 선택지.
        public enum RelevanceChoice: Equatable, Sendable {
            /// 포트폴리오 다시 올리기 — STEP 4 로 되돌린다.
            case reuploadPortfolio
            /// 집중 프로젝트 없이 진행 — freeText 를 비우고 재분석한다.
            case proceedWithoutFocus
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 중도 이탈(X) — dismiss 는 부모(AppFeature)가 처리한다.
            case dismiss
            /// 온보딩 완료(분석까지 끝) — 준비된 세션 id 를 넘긴다. 부모가 Part2 진입 등으로 전환한다.
            case finished(sessionId: Int)
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
                    state.data.jd = submission
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

            // 분석 — 완료면 세션 id 를 들고 위저드 종료, 연관성 실패면 집중 프로젝트로 되돌림, X 면 이탈.
            case let .path(.element(id: _, action: .analysis(.delegate(action)))):
                switch action {
                case let .completed(sessionId):
                    return .send(.delegate(.finished(sessionId: sessionId)))
                case .relevanceCheckFailed:
                    // PRD S3.5 — 연관성 부족 시 분석을 pop 하고 집중 프로젝트로 되돌린다.
                    state.relevanceFailureCount += 1
                    _ = state.path.popLast()
                    if state.relevanceFailureCount >= Self.relevanceFailureLimit {
                        // 4회째 — [포폴 다시 올리기 / 집중 프로젝트 없이 진행] 두 선택지.
                        state.relevanceChoice = Self.relevanceChoiceDialog()
                    } else {
                        // 그 전까지는 경고 문구와 함께 재입력을 유도한다.
                        setFocusProjectWarning(&state, Self.relevanceWarningMessage)
                    }
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            // 4회 실패 다이얼로그 — 포폴 재업로드(STEP4 복귀) / 집중 프로젝트 없이 재분석.
            case .relevanceChoice(.presented(.reuploadPortfolio)):
                state.relevanceFailureCount = 0
                _ = state.path.popLast()   // 집중 프로젝트도 pop → 포트폴리오 업로드(STEP4)
                return .none

            case .relevanceChoice(.presented(.proceedWithoutFocus)):
                state.relevanceFailureCount = 0
                state.data.freeText = nil
                state.path.append(.analysis(.init(data: state.data)))
                return .none

            case .relevanceChoice:
                return .none

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$relevanceChoice, action: \.relevanceChoice)
    }

    /// 스택 최상단(집중 프로젝트) 스텝에 연관성 경고 문구를 주입한다.
    private func setFocusProjectWarning(_ state: inout State, _ message: String) {
        guard let lastId = state.path.ids.last,
              case var .focusProject(focusProject)? = state.path[id: lastId] else { return }
        focusProject.relevanceWarning = message
        state.path[id: lastId] = .focusProject(focusProject)
    }

    /// 연관성 4회 실패 다이얼로그 (PRD S3.5 확정 문구).
    static func relevanceChoiceDialog() -> ConfirmationDialogState<Action.RelevanceChoice> {
        ConfirmationDialogState {
            TextState("포트폴리오에서 그 내용을 계속 찾지 못했어요")
        } actions: {
            ButtonState(action: .reuploadPortfolio) { TextState("포트폴리오 다시 올리기") }
            ButtonState(action: .proceedWithoutFocus) { TextState("집중 프로젝트 없이 진행") }
            ButtonState(role: .cancel) { TextState("닫기") }
        } message: {
            TextState("포트폴리오를 다시 업로드하거나, 집중 프로젝트 없이 진행할 수 있어요.")
        }
    }
}

// Path.State(=@Reducer enum 생성물)에 Equatable 합성 — 모든 스텝 State 가 Equatable 이므로 성립.
extension OnboardingFeature.Path.State: Equatable {}

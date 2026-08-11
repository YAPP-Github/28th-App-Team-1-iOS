//
//  OnboardingMainProjectFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Foundation

// Figma «Onboarding_MainProject» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-9732

// @lat: [[onboarding#대표 프로젝트]]
/// 온보딩 STEP 3 — 대표 프로젝트 입력(선택 스텝, 마지막 수집 단계). 집중적으로 보고 싶은
/// 프로젝트 내용을 자유 텍스트(최대 300자)로 받아 delegate(.continueRequested(freeText:))로
/// 코디네이터에 올린다. 서버 페이로드 `InterviewConfig.freeText`(10~300자, 선택)에 대응하며,
/// 빈 입력은 nil 로 올려 "건너뜀"을 뜻한다 — 선택 항목이라 계속하기는 항상 활성이고,
/// 네비바 «건너뛰기»도 같은 신호(freeText: nil)로 합류한다.
@Reducer
public struct OnboardingMainProjectFeature {
    @ObservableState
    public struct State: Equatable {
        /// 입력 상한 — 입력창 카운터 «n/300»의 분모. 서버 스펙(10~300자)의 상한과 동일.
        /// 카운터 표시와 초과분 잘라내기는 `HilitTextEditor(maxLength:)` 가 하고, 여기 클램프는
        /// View 를 안 거치는 경로(코디네이터 복원·테스트)까지 덮는 안전망이다.
        public static let maxTextLength = 300
        /// 입력 하한 — 서버 스펙(10~300자)의 하한과 동일. 선택 항목이라 빈 입력(스킵)에는 적용 안 하고,
        /// 입력이 있을 때만 continue 에서 로컬 선검증한다 (서버 INVALID_FREETEXT_LENGTH 왕복 전 차단, PRD §7).
        public static let minTextLength = 10

        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 대표 프로젝트 설명 입력값. 선택 항목 — 비어 있어도 계속하기가 가능하다.
        public var projectDescription: String
        /// 입력창 아래 경고 문구 — 하한 미달(로컬 선검증) 또는 연관성 실패(PRD S3.5, 코디네이터 주입).
        /// 슬롯 1개, 마지막 설정이 노출된다. 편집하면 사라진다.
        public var inputWarning: String?
        /// 스킵 툴팁 자동 소멸 여부 — onAppear 후 tooltipDuration(3초)이 지나면 true, 이후 유지.
        public var isTooltipExpired: Bool = false

        /// «나중에 등록해도 괜찮아요!» 스킵 툴팁 노출 — 진입 후 3초 동안만.
        public var showsSkipTooltip: Bool { !isTooltipExpired }

        public init(
            step: Int = 3,
            totalSteps: Int = 3,
            projectDescription: String = "",
            inputWarning: String? = nil
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.projectDescription = projectDescription
            self.inputWarning = inputWarning
        }
    }

    /// 하한 미달 시 노출 문구 — 서버 INVALID_FREETEXT_LENGTH 와 같은 길이 규칙(10~300자)을 말로 옮긴 것.
    /// 주어는 스텝 이름(대표 프로젝트)이 아니라 화면 어휘(«프로젝트 내용 입력» 라벨·타이틀)를 따른다.
    static let lengthWarningMessage = "프로젝트 내용은 10자 이상 300자 이하로 입력해 주세요."

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다 — 텍스트 입력은 binding 경유.
        @CasePathable
        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case onAppear
            case userTappedBack
            case userTappedClose
            case userTappedContinue
            /// 네비바 trailing «건너뛰기» — 입력을 버리고 선택 스텝을 넘긴다.
            case userTappedSkip
        }

        /// effect 결과. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// 스킵 툴팁 노출 시간(3초) 경과 — 툴팁을 감춘다.
            case tooltipExpired
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 스텝 완료 — 입력값(앞뒤 공백 제거)을 올린다. 빈 입력·건너뛰기는 nil (선택 항목 건너뜀).
            case continueRequested(freeText: String?)
            /// 이전 스텝으로 — pop 은 코디네이터 몫.
            case backRequested
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    /// 스킵 툴팁 자동 소멸까지의 시간 — 진입 후 이만큼 지나면 툴팁을 감춘다.
    static let tooltipDuration: Duration = .seconds(3)

    private enum CancelID { case tooltip }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)

        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 진입 후 3초 뒤 툴팁 소멸 — 이미 소멸했으면(뒤로가기 재진입 등) 재예약하지 않는다.
                guard !state.isTooltipExpired else { return .none }
                return .run { send in
                    try await clock.sleep(for: Self.tooltipDuration)
                    await send(.inner(.tooltipExpired))
                }
                .cancellable(id: CancelID.tooltip, cancelInFlight: true)

            case .inner(.tooltipExpired):
                state.isTooltipExpired = true
                return .none

            case .view(.binding):
                // 유일한 바인딩 필드(projectDescription)의 300자 상한 클램프 — 초과분은 잘라낸다.
                if state.projectDescription.count > State.maxTextLength {
                    state.projectDescription = String(state.projectDescription.prefix(State.maxTextLength))
                }
                // 편집을 시작하면 이전 경고(하한 미달·연관성)는 지운다.
                state.inputWarning = nil
                return .none

            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .view(.userTappedContinue):
                let trimmed = state.projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                // 선택 항목 — 빈 입력(공백만 포함)은 스킵(nil)으로 통과.
                if trimmed.isEmpty {
                    return .send(.delegate(.continueRequested(freeText: nil)))
                }
                // 입력이 있으면 하한 10자를 로컬 선검증 — 미달 시 서버 왕복 없이 경고만 노출하고 막는다.
                guard trimmed.count >= State.minTextLength else {
                    state.inputWarning = Self.lengthWarningMessage
                    return .none
                }
                return .send(.delegate(.continueRequested(freeText: trimmed)))

            case .view(.userTappedSkip):
                // 입력 중이던 값이 있어도 버린다 — «건너뛰기»는 «이 스텝을 안 채운다»는 뜻이라
                // 계속하기의 빈 입력 경로와 같은 신호로 합류한다(하한 선검증도 타지 않는다).
                return .send(.delegate(.continueRequested(freeText: nil)))

            case .delegate:
                return .none
            }
        }
    }
}

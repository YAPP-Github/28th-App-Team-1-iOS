//
//  OnboardingFocusProjectFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import Foundation

// @lat: [[onboarding#집중 프로젝트]]
/// 온보딩 STEP 5 — 집중 프로젝트 입력(선택 스텝, 마지막 단계). 집중적으로 보고 싶은
/// 프로젝트 내용을 자유 텍스트(최대 300자)로 받아 delegate(.continueRequested(freeText:))로
/// 코디네이터에 올린다. 서버 페이로드 `InterviewConfig.freeText`(10~300자, 선택)에 대응하며,
/// 빈 입력은 nil 로 올려 "건너뜀"을 뜻한다 — 선택 항목이라 계속하기는 항상 활성이다.
@Reducer
public struct OnboardingFocusProjectFeature {
    @ObservableState
    public struct State: Equatable {
        /// 입력 상한 — 카운터 «n/300자»의 분모. 서버 스펙(10~300자)의 상한과 동일.
        public static let maxTextLength = 300
        /// 입력 하한 — 서버 스펙(10~300자)의 하한과 동일. 선택 항목이라 빈 입력(스킵)에는 적용 안 하고,
        /// 입력이 있을 때만 continue 에서 로컬 선검증한다 (서버 INVALID_FREETEXT_LENGTH 왕복 전 차단, PRD §7).
        public static let minTextLength = 10

        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 집중 프로젝트 설명 입력값. 선택 항목 — 비어 있어도 계속하기가 가능하다.
        public var projectDescription: String
        /// 입력창 하단 경고 문구 — 하한 미달(로컬 선검증) 또는 연관성 실패(PRD S3.5, 코디네이터 주입).
        /// 슬롯 1개, 마지막 설정이 노출된다. 편집(입력/클리어) 시 사라진다.
        public var inputWarning: String?
        /// 스킵 툴팁 자동 소멸 여부 — onAppear 후 tooltipDuration(3초)이 지나면 true, 이후 유지.
        public var isTooltipExpired: Bool = false

        /// 입력이 있을 때만 입력창의 클리어(X) 버튼을 노출한다.
        public var isClearButtonVisible: Bool { !projectDescription.isEmpty }
        /// 입력창 우하단 글자수 카운터 (예: "0/300자").
        public var characterCountLabel: String { "\(projectDescription.count)/\(Self.maxTextLength)자" }
        /// «나중에 등록해도 괜찮아요!» 스킵 툴팁 노출 — 진입 후 3초 동안만.
        public var showsSkipTooltip: Bool { !isTooltipExpired }

        public init(
            step: Int = 5,
            totalSteps: Int = 5,
            projectDescription: String = "",
            inputWarning: String? = nil
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.projectDescription = projectDescription
            self.inputWarning = inputWarning
        }
    }

    /// 하한 미달 시 노출 문구 — 서버 INVALID_FREETEXT_LENGTH 메시지와 동일하게 맞춘다.
    static let lengthWarningMessage = "집중 프로젝트 설명은 10자 이상 300자 이하로 입력해 주세요."

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다 — 텍스트 입력은 binding 경유.
        @CasePathable
        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case onAppear
            case userTappedClearText
            case userTappedBack
            case userTappedClose
            case userTappedContinue
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
            /// 스텝 완료 — 입력값(앞뒤 공백 제거)을 올린다. 빈 입력은 nil (선택 항목 건너뜀).
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

            case .view(.userTappedClearText):
                state.projectDescription = ""
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

            case .delegate:
                return .none
            }
        }
    }
}

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
        /// 하한(10자) 검증 UX 는 디자인 미정 — 서버 검증(FREETEXT_NOT_RELEVANT 등)에 위임한다.
        public static let maxTextLength = 300

        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 집중 프로젝트 설명 입력값. 선택 항목 — 비어 있어도 계속하기가 가능하다.
        public var projectDescription: String
        /// 연관성 실패로 되돌아왔을 때의 경고 문구 (PRD S3.5). 코디네이터가 주입하고 편집 시 사라진다.
        public var relevanceWarning: String?

        /// 입력이 있을 때만 입력창의 클리어(X) 버튼을 노출한다.
        public var isClearButtonVisible: Bool { !projectDescription.isEmpty }
        /// 입력창 우하단 글자수 카운터 (예: "0/300자").
        public var characterCountLabel: String { "\(projectDescription.count)/\(Self.maxTextLength)자" }

        public init(
            step: Int = 5,
            totalSteps: Int = 5,
            projectDescription: String = "",
            relevanceWarning: String? = nil
        ) {
            self.step = step
            self.totalSteps = totalSteps
            self.projectDescription = projectDescription
            self.relevanceWarning = relevanceWarning
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다 — 텍스트 입력은 binding 경유.
        @CasePathable
        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case userTappedClearText
            case userTappedBack
            case userTappedClose
            case userTappedContinue
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

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)

        Reduce { state, action in
            switch action {
            case .view(.binding):
                // 유일한 바인딩 필드(projectDescription)의 300자 상한 클램프 — 초과분은 잘라낸다.
                if state.projectDescription.count > State.maxTextLength {
                    state.projectDescription = String(state.projectDescription.prefix(State.maxTextLength))
                }
                // 편집을 시작하면 이전 연관성 경고는 지운다.
                state.relevanceWarning = nil
                return .none

            case .view(.userTappedClearText):
                state.projectDescription = ""
                state.relevanceWarning = nil
                return .none

            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .view(.userTappedContinue):
                let trimmed = state.projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                return .send(.delegate(.continueRequested(freeText: trimmed.isEmpty ? nil : trimmed)))

            case .delegate:
                return .none
            }
        }
    }
}

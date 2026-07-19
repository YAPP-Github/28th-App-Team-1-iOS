//
//  OnboardingJDLinkFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import DomainJDInterface
import Foundation

// @lat: [[onboarding#JD 링크]]
/// 온보딩 STEP 3 — 채용공고(JD) 링크 입력 (선택 스텝).
/// 링크 붙여넣기 / 본문 직접 입력은 같은 화면의 탭(모드) 전환이고,
/// 링크 검증의 로딩·에러·성공은 별도 화면이 아니라 `LinkValidation` 하위 상태로 표현한다.
/// 수집 결과는 delegate(.continueRequested(JDSubmission?))로 코디네이터에 올린다 — nil 은 스킵.
@Reducer
public struct OnboardingJDLinkFeature {
    /// JD 입력 방식 — Figma «3. 링크 입력»(1609:8597) ↔ «3.2 직접입력»(1991:7433) 탭.
    public enum InputMode: Equatable, Sendable {
        /// 채용공고 링크 붙여넣기 (기본 탭 «JD 붙여넣기»)
        case link
        /// JD 본문 직접 입력 (크롤링 실패 폴백 탭 «직접 입력하기»)
        case directText
    }

    /// 링크 검증(서버 크롤링+정제) 하위 상태 — 텍스트필드의 로딩/에러/성공 변형으로 렌더된다.
    public enum LinkValidation: Equatable, Sendable {
        case idle
        /// «3.1 링크 로딩»(1716:5283) — 필드 잠금 + «분석 중» + 진행 스트립.
        case loading
        /// «3.1.1 링크 에러»(1716:5334) — 서버 message 또는 기본 문구.
        case failure(message: String)
        /// «3.1.2 링크 성공»(1716:5393) — 서버가 JD 를 캐싱한 상태.
        case success
    }

    /// 이 스텝이 수집한 JD — 도메인 `JobDescriptionInput`(.url/.text)과 1:1 로 대응한다.
    public enum JDSubmission: Equatable, Sendable {
        /// 검증 성공한 채용공고 URL
        case link(String)
        /// 직접 입력한 JD 본문
        case text(String)
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        public var mode: InputMode = .link
        /// «JD 붙여넣기» 탭의 링크 입력값.
        public var linkText: String = ""
        /// «직접 입력하기» 탭의 JD 본문 입력값.
        public var directText: String = ""
        public var linkValidation: LinkValidation = .idle

        /// 검증 성공 후에는 직접 입력 탭이 비활성화된다 (Figma 1716:5393 — 탭 텍스트 gray).
        public var isDirectTextDisabled: Bool { linkValidation == .success }
        /// 분석 중에는 링크 필드 편집을 잠근다 (Figma 1716:5283 — 필드 회색 배경).
        public var isLinkFieldDisabled: Bool { linkValidation == .loading }
        /// 스킵 안내 툴팁 — 현재 탭의 입력이 비어 있는 동안만 노출 (1609:8597 · 1991:7433 에만 존재).
        public var showsSkipTooltip: Bool {
            switch mode {
            case .link: linkValidation == .idle && linkText.isEmpty
            case .directText: directText.isEmpty
            }
        }

        public init(step: Int = 3, totalSteps: Int = 5) {
            self.step = step
            self.totalSteps = totalSteps
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        @CasePathable
        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case userSelectedMode(InputMode)
            /// 키보드 리턴 — 디바운스 없이 즉시 검증.
            case userSubmittedLink
            case userTappedClearLink
            case userTappedClearDirectText
            case userTappedBack
            case userTappedClose
            case userTappedContinue
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// 디바운스 경과(또는 제출) — 검증 API 호출 시작.
            case validationStarted
            case linkValidated(JDValidation)
            case linkValidationFailed
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 스텝 완료 — 수집한 JD. 선택 스텝이므로 nil(스킵) 가능.
            case continueRequested(JDSubmission?)
            /// 뒤로(하단 «이전으로») — 코디네이터가 스택을 pop.
            case backRequested
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    /// 붙여넣기 후 자동 검증까지의 디바운스 — «JD 붙여넣기» UX (붙여넣으면 곧바로 분석 시작).
    static let validationDebounce: Duration = .milliseconds(600)
    /// 네트워크 오류 등 서버 message 가 없을 때의 기본 에러 문구.
    static let fallbackErrorMessage = "링크를 분석하지 못했어요. 링크를 확인해 주세요." // TODO: 확정 카피 반영

    private enum CancelID { case validate }

    @Dependency(\.jdClient) var jdClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)

        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)
            case let .inner(action):
                return reduceInner(&state, action)
            case .delegate:
                return .none
            }
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .binding(\.linkText):
            // 링크가 바뀌면 이전 검증 결과는 무효 — 비어 있지 않으면 재검증을 디바운스 예약한다.
            state.linkValidation = .idle
            guard !trimmedLink(state).isEmpty else {
                return .cancel(id: CancelID.validate)
            }
            return .run { send in
                try await clock.sleep(for: Self.validationDebounce)
                await send(.inner(.validationStarted))
            }
            .cancellable(id: CancelID.validate, cancelInFlight: true)

        case .binding:
            return .none

        case let .userSelectedMode(mode):
            guard !(mode == .directText && state.isDirectTextDisabled) else { return .none }
            state.mode = mode
            return .none

        case .userSubmittedLink:
            guard !trimmedLink(state).isEmpty, state.linkValidation != .loading else { return .none }
            // 즉시 시작 — validationStarted 의 effect 가 같은 CancelID 로 디바운스 예약분을 대체한다.
            return .send(.inner(.validationStarted))

        case .userTappedClearLink:
            state.linkText = ""
            state.linkValidation = .idle
            return .cancel(id: CancelID.validate)

        case .userTappedClearDirectText:
            state.directText = ""
            return .none

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case .userTappedContinue:
            switch state.mode {
            case .link:
                switch state.linkValidation {
                case .loading:
                    // 분석 중 탭은 무시 — 결과 확인 후 진행. TODO: 디자인 확정 시 재검토 (CTA 비활성 표기 없음).
                    return .none
                case .success:
                    return .send(.delegate(.continueRequested(.link(trimmedLink(state)))))
                case .idle, .failure:
                    // 선택 스텝 — 검증되지 않은 링크는 버리고 스킵한다 (툴팁 안내와 일치).
                    return .send(.delegate(.continueRequested(nil)))
                }
            case .directText:
                let text = state.directText.trimmingCharacters(in: .whitespacesAndNewlines)
                return .send(.delegate(.continueRequested(text.isEmpty ? nil : .text(text))))
            }
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case .validationStarted:
            state.linkValidation = .loading
            let url = trimmedLink(state)
            return .run { send in
                await send(.inner(.linkValidated(try await jdClient.validate(url))))
            } catch: { _, send in
                await send(.inner(.linkValidationFailed))
            }
            .cancellable(id: CancelID.validate, cancelInFlight: true)

        case let .linkValidated(validation):
            // HTTP 200 이어도 valid 로 성공을 판단한다 (JDClient 계약).
            state.linkValidation = validation.valid
                ? .success
                : .failure(message: validation.message ?? Self.fallbackErrorMessage)
            return .none

        case .linkValidationFailed:
            state.linkValidation = .failure(message: Self.fallbackErrorMessage)
            return .none
        }
    }

    private func trimmedLink(_ state: State) -> String {
        state.linkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

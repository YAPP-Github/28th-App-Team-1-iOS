//
//  ReportPeerFeedbackFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainFeedbackShareInterface
import DomainInterviewReportInterface

// @lat: [[report#지인 피드백]]
/// 지인 피드백 요청 — 리포트 메인의 «지인에게 면접 영상 보내기» 로 진입한다.
/// 지인에게 평가받을 태도 항목을 골라 공유 링크를 만드는 화면 (Figma «Report_PeerFeedback_RequestItems» 1964:727).
///
/// 지인에게 넘기는 payload 는 영상과 질문 경계까지다. AI 피드백(하이라이트·진단·다음 대비)은
/// 넘기지 않는다 — 지인 평가가 AI 평가에 오염되면 4.6 의 «지인 vs AI» 2축 비교가 무의미해진다.
/// 그래서 이 화면이 서버로 보내는 것도 **항목 코드뿐**이다 ([[api#Feedback Share]]).
///
/// 항목은 생성 시점에 링크로 잠긴다 — 만든 뒤 바꿀 수 없고 면접당 활성 링크는 1개다(409 `alreadyExists`).
/// 그래서 생성은 되돌릴 수 없는 사건이고, 화면은 성공 즉시 완료 모달로 링크 복사만 남긴다.
@Reducer
public struct ReportPeerFeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public let sessionId: Int
        /// 지인에게 평가받을 태도 항목. 서버 계약은 1~5개 — 0개면 400 이라 CTA 를 `.disabled` 로 막는다.
        public var selectedAxes: Set<AttitudeAxisKind> = []
        public var isCreating = false
        /// 생성된 공유 링크 — 생성 성공 후엔 항상 남는다 (항목이 잠겨 재생성이 없으므로).
        public var createdLink: String?
        /// 완료 모달 표시 여부 (Figma 3165:15392). 복사를 누르면 닫힌다.
        public var isCompletionModalVisible = false
        /// 시스템 공유 시트 — 복사 직후 이어서 뜬다 (복사 + 바로 보내기 겸용).
        public var isShareSheetPresented = false
        /// 하단 토스트 문구 — 복사 완료·생성 실패 안내를 같은 자리에서 쓴다.
        public var toast: String?

        public init(sessionId: Int) {
            self.sessionId = sessionId
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case onAppear
            case userTappedBack
            case userToggledAxis(AttitudeAxisKind, isOn: Bool)
            case userTappedCreateLink
            case userTappedCopyLink
        }

        public enum Inner: Equatable, Sendable {
            case shareLinkCreated(token: String)
            case shareLinkFailed(message: String)
            case toastDismissed
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
        }
    }

    private enum CancelID { case toast }

    /// 토스트가 떠 있는 시간.
    private static let toastDuration: Duration = .seconds(2)

    @Dependency(\.feedbackShareClient) var feedbackShareClient
    @Dependency(\.pasteboard) var pasteboard
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
        case .binding:
            return .none

        case .onAppear:
            return .none

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case let .userToggledAxis(axis, isOn):
            if isOn {
                state.selectedAxes.insert(axis)
            } else {
                state.selectedAxes.remove(axis)
            }
            return .none

        case .userTappedCreateLink:
            // 항목 0개는 View 가 `.disabled` 로 막는다 — 여기 도달하면 방어만.
            guard !state.isCreating, !state.selectedAxes.isEmpty else { return .none }
            state.isCreating = true
            let sessionId = state.sessionId
            // 서버로 나가는 순서는 화면 순서(시선·표정·자세·손동작·목소리)로 고정한다 —
            // Set 의 순회 순서는 실행마다 달라서 게스트 화면의 항목 순서가 흔들린다.
            let selected = state.selectedAxes
            let axes = AttitudeAxisKind.allCases
                .filter(selected.contains)
                .map(\.rawValue)
            return .run { send in
                let created = try await feedbackShareClient.create(sessionId, axes)
                await send(.inner(.shareLinkCreated(token: created.token)))
            } catch: { error, send in
                await send(.inner(.shareLinkFailed(message: Self.failureMessage(for: error))))
            }

        case .userTappedCopyLink:
            guard let link = state.createdLink else { return .none }
            // 복사 + 시스템 공유 시트를 이어서 연다 — 붙여넣기와 바로 보내기 둘 다 지원.
            // 모달은 닫고 화면은 남는다 (링크는 이미 만들어졌고 항목은 잠겼다).
            state.isCompletionModalVisible = false
            state.isShareSheetPresented = true
            return .merge(
                .run { _ in pasteboard.copy(link) },
                showToast("링크를 복사했어요.", &state)
            )
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .shareLinkCreated(token):
            state.isCreating = false
            state.createdLink = Self.shareLink(token: token)
            state.isCompletionModalVisible = true
            return .none

        case let .shareLinkFailed(message):
            state.isCreating = false
            return showToast(message, &state)

        case .toastDismissed:
            state.toast = nil
            return .none
        }
    }

    /// 토스트를 띄우고 정해진 시간 뒤 스스로 내린다. 연달아 뜨면 뒤엣것만 남는다(`cancelInFlight`).
    private func showToast(_ message: String, _ state: inout State) -> Effect<Action> {
        state.toast = message
        return .run { send in
            try await clock.sleep(for: Self.toastDuration)
            await send(.inner(.toastDismissed))
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }

    /// 토큰 → 지인이 열 링크. 조립은 클라이언트 책임이다 ([[api#Feedback Share]]).
    /// 도메인은 hilit.my 로 확정 (2026-07-29). 경로 구조는 웹 게스트 페이지 스펙 확정 시 재확인.
    private static func shareLink(token: String) -> String {
        "https://hilit.my/feedback/\(token)"
    }

    /// 실패 안내 문구. 서버가 준 `message` 가 있는 항목 검증 실패만 그대로 노출하고,
    /// 나머지는 사용자가 할 수 있는 행동으로 번역한다.
    private static func failureMessage(for error: any Error) -> String {
        switch error as? FeedbackShareError {
        case .alreadyExists:
            "이미 만들어 둔 링크가 있어요."
        case let .invalidAxes(message):
            message
        case .shareNotFound, .sessionNotFound:
            "면접 정보를 찾을 수 없어요."
        case .sessionExpired:
            "다시 로그인해 주세요."
        case .networkFailure:
            "네트워크 연결을 확인해 주세요."
        default:
            "링크를 만들지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

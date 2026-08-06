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
/// 지인에게 평가받을 태도 항목을 골라 공유 링크를 만드는 화면 (Figma «Report_PeerFeedback_RequestItems» 443:8006).
///
/// 지인에게 넘기는 payload 는 영상과 질문 경계까지다. AI 피드백(하이라이트·진단·다음 대비)은
/// 넘기지 않는다 — 지인 평가가 AI 평가에 오염되면 4.6 의 «지인 vs AI» 2축 비교가 무의미해진다.
/// 그래서 이 화면이 서버로 보내는 것도 **항목 코드뿐**이다 ([[api#Feedback Share]]).
///
/// 항목은 생성 시점에 링크로 잠긴다 — 만든 뒤 바꿀 수 없고 면접당 활성 링크는 1개다(409 `alreadyExists`).
/// 그래서 생성은 되돌릴 수 없는 사건이고, 화면은 성공 즉시 완료 모달로 링크 복사만 남긴다.
///
/// **재생성은 없지만 재복사는 있다** — 공유 시트를 취소하면 링크가 손에 남지 않는다. 그래서 진입 때
/// `status` 로 활성 링크를 회수하고(있으면 항목을 잠근 채 CTA 를 «링크 복사하기» 로 바꾼다),
/// 생성이 409 로 걸려도 같은 회수로 완료 모달을 다시 띄운다.
@Reducer
public struct ReportPeerFeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public let sessionId: Int
        /// 지인에게 평가받을 태도 항목. 서버 계약은 1~5개 — 0개면 400 이라 CTA 를 `.disabled` 로 막는다.
        public var selectedAxes: Set<AttitudeAxisKind> = []
        public var isCreating = false
        /// 공유 링크 — 생성 성공 또는 **진입·409 회수**로 채워지고, 채워진 뒤엔 항상 남는다
        /// (항목이 잠겨 재생성이 없으므로).
        public var createdLink: String?
        /// 이 링크가 방금 만든 것이 아니라 서버에서 회수한 기존 링크인지 — 완료 모달 문구가 갈린다.
        public var isLinkRecovered = false
        /// 완료 모달 표시 여부 (Figma 443:8082 의 모달 443:8121). 복사를 누르면 닫힌다.
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
            /// 서버에 이미 있던 활성 링크 회수 — 진입 조회(`presentsModal: false`)와 생성 409
            /// (`presentsModal: true`)가 같은 재료를 쓰고 뒷처리만 다르다.
            case existingShareLoaded(token: String, axes: [String], presentsModal: Bool)
            case shareLinkCreated(token: String)
            case shareLinkFailed(message: String)
            case shareSheetRequested
            case toastDismissed
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
        }
    }

    private enum CancelID { case share, toast }

    /// 완료 모달이 닫히고 공유 시트가 올라오기까지 벌려 두는 간격.
    /// 모달은 `fullScreenCover`(`.hilitModal`)라 닫히는 도중에 시트를 올리면 시스템이 둘째 표출을 삼킨다.
    private static let modalDismissGap: Duration = .milliseconds(400)

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
            // 이미 만들어 둔 활성 링크가 있으면 회수한다 — 공유 시트를 취소해 링크를 잃어버린 사용자가
            // 다시 들어오는 경로다. 항목은 그때 잠긴 값이라 화면은 재복사만 남는다.
            guard state.createdLink == nil else { return .none }
            return recoverExistingShare(sessionId: state.sessionId, presentsModal: false)

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
            return createShareLink(sessionId: state.sessionId, axes: state.selectedAxes)

        case .userTappedCopyLink:
            guard let link = state.createdLink else { return .none }
            // 복사 + 시스템 공유 시트를 이어서 연다 — 붙여넣기와 바로 보내기 둘 다 지원.
            // 모달은 닫고 화면은 남는다 (링크는 이미 만들어졌고 항목은 잠겼다).
            state.isCompletionModalVisible = false
            return .merge(
                .run { _ in pasteboard.copy(link) },
                showToast("링크를 복사했어요.", &state),
                .run { send in
                    try await clock.sleep(for: Self.modalDismissGap)
                    await send(.inner(.shareSheetRequested))
                }
            )
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .existingShareLoaded(token, axes, presentsModal):
            state.isCreating = false
            state.createdLink = Self.shareLink(token: token)
            state.isLinkRecovered = true
            // 항목은 생성 시점에 잠긴 값이라 서버가 답이다 — 모르는 코드는 버린다.
            state.selectedAxes = Set(axes.compactMap { AttitudeAxisKind(rawCode: $0) })
            state.isCompletionModalVisible = presentsModal
            return .none

        case let .shareLinkCreated(token):
            state.isCreating = false
            state.createdLink = Self.shareLink(token: token)
            state.isCompletionModalVisible = true
            return .none

        case let .shareLinkFailed(message):
            state.isCreating = false
            return showToast(message, &state)

        case .shareSheetRequested:
            state.isShareSheetPresented = true
            return .none

        case .toastDismissed:
            state.toast = nil
            return .none
        }
    }

    /// 링크 생성. 서버로 나가는 항목 순서는 화면 순서(시선·표정·자세·손동작·목소리)로 고정한다 —
    /// `Set` 의 순회 순서는 실행마다 달라서 게스트 화면의 항목 순서가 흔들린다.
    /// 409(활성 링크 존재)는 실패로 끝내지 않는다 — 재생성은 없지만 **재복사** 는 있어야 한다.
    private func createShareLink(sessionId: Int, axes selected: Set<AttitudeAxisKind>) -> Effect<Action> {
        let axes = AttitudeAxisKind.allCases.filter(selected.contains).map(\.rawValue)
        return .run { send in
            let created = try await feedbackShareClient.create(sessionId, axes)
            await send(.inner(.shareLinkCreated(token: created.token)))
        } catch: { error, send in
            guard (error as? FeedbackShareError) == .alreadyExists,
                  let status = try? await feedbackShareClient.status(sessionId),
                  status.status == .active
            else {
                await send(.inner(.shareLinkFailed(message: Self.failureMessage(for: error))))
                return
            }
            await send(.inner(.existingShareLoaded(
                token: status.token,
                axes: status.axes ?? [],
                presentsModal: true
            )))
        }
        // 진입 회수와 같은 ID — 회수가 나는 동안 생성을 탭하면 회수를 끊고 생성이 이어받는다
        // (링크가 실존하면 409 → 위 catch 가 다시 회수하므로 결과는 같고, 요청만 단일 비행이 된다).
        .cancellable(id: CancelID.share, cancelInFlight: true)
    }

    /// 서버에 이미 있는 활성 링크를 회수한다 — 링크 미생성(404)이 정상 경로라 조회 실패로 화면을 막지 않고,
    /// ACTIVE 가 아닌 링크(무효화·비공개)는 복사해도 지인이 못 열어 회수 대상이 아니다.
    // TODO(prd-외): 재복사 동선 전체(진입 회수·409 회수·CTA 잠금)가 PRD 에 없는 재량 구현 —
    //               «공유 시트 취소 = 링크 유실» 막다른 길을 관례로 메웠다. 스펙 확정 시 재검토.
    private func recoverExistingShare(sessionId: Int, presentsModal: Bool) -> Effect<Action> {
        .run { send in
            let status = try await feedbackShareClient.status(sessionId)
            guard status.status == .active else { return }
            await send(.inner(.existingShareLoaded(
                token: status.token,
                axes: status.axes ?? [],
                presentsModal: presentsModal
            )))
        } catch: { _, _ in
            // 생성 시 409 로 다시 걸리므로 여기서 사용자에게 알릴 것이 없다.
        }
        .cancellable(id: CancelID.share, cancelInFlight: true)
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
    /// 409(활성 링크 존재)는 회수 경로가 먼저 가로채므로 회수까지 실패했을 때만 여기 온다.
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

// MARK: - 표시 파생값

public extension ReportPeerFeedbackFeature.State {
    /// 항목 잠김 — 활성 링크가 있으면(방금 만들었든 회수했든) 항목을 바꿀 수 없다.
    /// 그 상태의 화면은 «생성» 이 아니라 «재복사» 다.
    var isAxisLocked: Bool { createdLink != nil }
}

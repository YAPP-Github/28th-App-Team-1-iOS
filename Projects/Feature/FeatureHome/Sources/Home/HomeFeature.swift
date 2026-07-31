//
//  HomeFeature.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import Foundation

// @lat: [[home]]
/// 홈 — 홈 화면 자체를 `phase` 하나로 관리한다(GuestFeedback 패턴 — 선형 플로우가 아니라 서버 상태의 표시라
/// StackState 를 두지 않는다). phase 는 Figma 프레임 `HomeDefault`·`HomeReport` 와 1:1 이고, 면접 시작은
/// 홈의 상태가 아니라 위로 올라오는 화면이라 `StartInterviewFeature` 를 present 한다.
/// phase 는 서버 판정의 표시일 뿐 — 진실은 탭 시점 게이트(checkStartEligibility) 재검증.
@Reducer
public struct HomeFeature {
    /// 홈 화면 상태 — Figma 프레임 `HomeDefault`·`HomeReport` 와 1:1(docs/work/home-account.md §3).
    public enum Phase: Equatable, Sendable {
        /// HomeDefault — 기본 상태(리포트 없음).
        case `default`
        /// HomeReport — 면접 기록(레포트) 표시 상태.
        case report(ReportVariant)
    }

    /// HomeReport 하위 변형 — 축은 «오랜만이에요 OO님!» 인사말을 띄우는지 하나다.
    /// 리포트 목록·바텀시트는 두 변형이 같다.
    public enum ReportVariant: Equatable, Sendable {
        /// 오랜만에 돌아온 사용자 — 인사말을 띄운다.
        case returning
        /// 최근에 다녀간 사용자 — 인사말을 숨기고 스크롤 안내만 남긴다.
        case recent
    }

    /// 리포트 행 표시 모델 — 위젯② 면접 기록 한 줄.
    /// `dateText` 는 이미 포맷된 문자열이다(«7월 11일 월» 포맷은 목록을 만드는 쪽 몫).
    // TODO: `DomainInterviewReport` 의 목록 모델로 이관 — 지금 `.domain(interface: .interviewReport)` 를
    //       붙이면 «외부 IO 없는 Feature» 전제가 깨진다. 목록 계약은 서버 협의(미결 6-1) 후 확정.
    public struct Report: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let dateText: String
        public let title: String

        public init(id: UUID = UUID(), dateText: String, title: String) {
            self.id = id
            self.dateText = dateText
            self.title = title
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 화면 상태 — 홈 진입 시 로드 결과(잔여·기록·포폴)가 결정한다.
        public var phase: Phase = .default
        // TODO: 서버 프로필(nickname) — 홈 진입 로드에 붙으면 기본값을 지운다(미결 6-1).
        /// 인사말에 넣는 사용자 이름.
        public var userName: String
        /// 리포트 목록 — 최신순. 개수는 여기서 파생한다(`reports.count`), 따로 들지 않는다.
        public var reports: IdentifiedArrayOf<Report>
        /// 펼친 행 — 시안은 최신 1개가 펼쳐진 상태다. nil 이면 전부 접힘.
        public var expandedReportID: Report.ID?
        /// present 된 면접 시작 화면 — 홈 탭에 NavigationStack 이 없어 push 가 아니라 cover 다.
        @Presents public var startInterview: StartInterviewFeature.State?
        // TODO: 홈 진입 로드(잔여·포폴)가 정해야 하고, 진실은 탭 시점 게이트 `checkStartEligibility` 재검증
        //       (미결 6-1 서버 협의 대기).
        /// 다음에 열 면접 시작 화면의 변형.
        public var nextStartVariant: StartInterviewFeature.Variant = .first
        /// dev 진입점 노출 여부 — AppFeature 가 dev 빌드에서만 켠다 (온보딩 본체 통합 전 임시 진입).
        public var showsOnboardingEntry: Bool
        /// dev 디버그 로그아웃 버튼 노출 여부 — AppFeature 가 dev 빌드에서만 켠다.
        public var showsDebugLogout: Bool

        public init(
            phase: Phase = .default,
            userName: String = "재원",
            reports: [Report] = [],
            showsOnboardingEntry: Bool = false,
            showsDebugLogout: Bool = false
        ) {
            self.phase = phase
            self.userName = userName
            self.reports = IdentifiedArray(uniqueElements: reports)
            self.expandedReportID = reports.first?.id
            self.showsOnboardingEntry = showsOnboardingEntry
            self.showsDebugLogout = showsDebugLogout
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case startInterview(PresentationAction<StartInterviewFeature.Action>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            // TODO: 홈 진입 4종 로드(잔여·기록 리스트·진행 중 세션·포폴 상태) — 묶음 API 여부 서버 협의(미결 6-1) 후 배선.
            //       기록 리스트 응답은 `inner(.reportsLoaded)` 로 돌아온다.
            case onAppear
            /// 면접 시작 요청 — 면접 시작 화면을 present 한다.
            case userTappedStartInterview
            /// 내비바 프로필 탭 — 마이페이지 진입 요청.
            case userTappedProfile
            /// 펼친 행의 [레포트 보기] 탭 — 리포트 상세 진입 요청.
            case userTappedReport(id: Report.ID)
            /// 리포트 행 탭 — 펼침 토글(홈 내부 상태, 화면 전환 아님).
            case userTappedReportRow(id: Report.ID)
            /// dev 진입 버튼 탭 — 온보딩 시작 요청.
            case userTappedOnboarding
            /// dev 디버그 로그아웃 탭 — 세션·토큰·draft 전체 삭제 요청.
            case userTappedLogout
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {
            /// 기록 리스트 로드 결과 — 목록과 phase 를 함께 갱신한다.
            case reportsLoaded([Report])
        }

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// 마이페이지 진입 요청 — 홈 밖 화면이라 조립은 AppFeature (Feature→Feature 금지).
            case profileRequested
            /// 리포트 상세 진입 요청 — 리포트 뷰는 홈 밖이라 조립은 AppFeature.
            case reportDetailRequested(id: Report.ID)
            /// 면접 시작 요청 — 면접 시작 화면의 [시작하기] 가 발원지. 전환은 AppFeature.
            case interviewStartRequested
            /// 면접 정보 수정 요청 — 면접 시작 화면의 [수정하기] 가 발원지. 전환은 AppFeature.
            case interviewInfoEditRequested
            /// dev 온보딩 진입 요청 — 조립은 AppFeature 가 한다 (Feature→Feature 금지).
            case onboardingRequested
            /// dev 디버그 로그아웃 요청 — orchestration(logout API·draft clear·State 리셋)은 AppFeature.
            case logoutRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .view(.userTappedStartInterview):
                state.startInterview = StartInterviewFeature.State(variant: state.nextStartVariant)
                return .none
            case .view(.userTappedProfile):
                return .send(.delegate(.profileRequested))
            case let .view(.userTappedReport(id)):
                return .send(.delegate(.reportDetailRequested(id: id)))
            case let .view(.userTappedReportRow(id)):
                // 재탭이면 접는다 — foldable 행은 홈 내부 상태다(docs/work/home-account.md §3 위젯②).
                state.expandedReportID = state.expandedReportID == id ? nil : id
                return .none
            case .view(.userTappedOnboarding):
                return .send(.delegate(.onboardingRequested))
            case .view(.userTappedLogout):
                return .send(.delegate(.logoutRequested))

            case let .inner(.reportsLoaded(reports)):
                state.reports = IdentifiedArray(uniqueElements: reports)
                state.expandedReportID = reports.first?.id
                // 인사말 변형(returning/recent) 판정 재료는 목록에 없다 — 목록 유무만 반영하고 변형은 유지한다.
                switch (reports.isEmpty, state.phase) {
                case (true, _):
                    state.phase = .default
                case (false, .report):
                    break
                case (false, .default):
                    state.phase = .report(.recent)
                }
                return .none

            case .startInterview(.presented(.delegate(.closeRequested))),
                 .startInterview(.presented(.delegate(.backToHomeRequested))):
                state.startInterview = nil
                return .none
            case .startInterview(.presented(.delegate(.startRequested))):
                // 면접 플로우는 다른 Feature 라 AppFeature 가 조립한다(Feature→Feature 금지).
                return .send(.delegate(.interviewStartRequested))
            case .startInterview(.presented(.delegate(.editInfoRequested))):
                return .send(.delegate(.interviewInfoEditRequested))
            case .startInterview:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$startInterview, action: \.startInterview) {
            StartInterviewFeature()
        }
    }
}

// MARK: - 시안 값

extension HomeFeature.Report {
    /// 시안(3368:17266)의 목록 5행 — **프리뷰·시안 확인 전용** 픽스처다.
    /// 실제 목록은 `inner(.reportsLoaded)` 로만 들어온다.
    public static let placeholders: [Self] = [
        .init(dateText: "7월 11일 월", title: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해 주셨어요"),
        .init(dateText: "7월 10일 월", title: "질문 의도를 되묻고 답변 범위를 좁혀 나갔어요"),
        .init(dateText: "7월 10일 월", title: "경험을 시간순으로 정리해 전달했어요"),
        .init(dateText: "7월 10일 월", title: "트레이드오프를 먼저 말하고 선택 이유를 덧붙였어요"),
        .init(dateText: "7월 10일 월", title: "성능 개선 결과를 지표로 설명했어요")
    ]
}

//
//  MyPageFeature.swift
//  FeatureMyPage
//
//  Created by 서정원 on 26/08/01.
//

import ComposableArchitecture

// Figma: «[Part5] 마이페이지» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-9709
//
// 서버 연동 전 단계다 — @Dependency 를 하나도 잡지 않고 State 초기값(목데이터)만으로 화면이 선다.
// 연동 시 추가되는 것은 ① Client 주입 ② onAppear 의 fetch effect ③ inner 응답 케이스뿐이고,
// 아래 view 액션·delegate 계약은 그대로 둔다.
// @lat: [[mypage#흐름]]
// depends-on: [[app#Cross-feature Routing]] — 레포트 열기·지인 피드백·로그아웃·회원탈퇴·파일 선택기는
//             delegate 로만 올린다(import 에 안 보이는 의존).
@Reducer
public struct MyPageFeature {
    // MARK: - 화면이 그리는 값

    /// 프로필 카드 한 장. 서버 스펙 확정 전이라 표시 문자열을 그대로 나른다(포맷은 연동 시 이 자리로 들어온다).
    public struct Profile: Equatable, Sendable {
        public var name: String
        public var jobGroup: String
        public var careerLevel: String
        public var remainingTickets: Int
        public var email: String

        public init(
            name: String,
            jobGroup: String,
            careerLevel: String,
            remainingTickets: Int,
            email: String
        ) {
            self.name = name
            self.jobGroup = jobGroup
            self.careerLevel = careerLevel
            self.remainingTickets = remainingTickets
            self.email = email
        }
    }

    /// 포트폴리오 파일 한 개.
    public struct PortfolioFile: Equatable, Sendable {
        public var name: String
        public var date: String?
        public var size: String?

        public init(name: String, date: String? = nil, size: String? = nil) {
            self.name = name
            self.date = date
            self.size = size
        }
    }

    /// «내 포트폴리오» 칸의 상태 — Figma 의 «포트폴리오 case» 프레임들이 그대로 케이스다.
    /// 판의 생김새가 상태마다 통째로 바뀌므로(`FileUpload` 와 같은 사정) Bool 조합이 아니라 enum 이다.
    public enum Portfolio: Equatable, Sendable {
        /// 업로드 전 — 업로드 유도 판 + «아직 첨부된 포트폴리오가 없어요» (MyPage_Portfolio_empty)
        case empty
        case uploading(PortfolioFile, progress: Double)
        case uploaded(PortfolioFile)
        case registered(PortfolioFile)
        case failed(PortfolioFile)
    }

    /// «내 면접 레포트» 목록 한 줄. 접힘 요약(`FoldableCard`)과 펼침 상세(`FoldableCardDetail`)가 한 값에서 나온다.
    public struct Report: Equatable, Identifiable, Sendable {
        public let id: String
        /// 접힘 제목 — 면접명 또는 포트폴리오 파일명.
        public var title: String
        public var date: String
        public var time: String
        /// 제목 아래 회색 메모 태그 («삭제된 포트폴리오»). nil 이면 숨김.
        public var note: String?
        /// 오른쪽 빨간 상태 태그 («생성 실패»). nil 이면 숨김.
        public var status: String?
        /// 상세 «직군 · 연차» 값.
        public var jobLevel: String
        /// 상세 «포트폴리오» 값.
        public var portfolioName: String
        /// 상세 «JD» 값. 링크·«직접 입력함»·«-» 가 다 들어온다.
        public var jobDescription: String
        /// 상세 맨 아래 오류 띠. nil 이면 숨김.
        public var detailError: String?
        /// 상세 버튼 두 개(«레포트 보기»·«지인 피드백 받기») 노출 여부.
        /// 시안에서 생성 실패·포트폴리오 삭제 케이스는 버튼이 없다.
        public var showsActions: Bool

        public init(
            id: String,
            title: String,
            date: String,
            time: String,
            note: String? = nil,
            status: String? = nil,
            jobLevel: String,
            portfolioName: String,
            jobDescription: String,
            detailError: String? = nil,
            showsActions: Bool = false
        ) {
            self.id = id
            self.title = title
            self.date = date
            self.time = time
            self.note = note
            self.status = status
            self.jobLevel = jobLevel
            self.portfolioName = portfolioName
            self.jobDescription = jobDescription
            self.detailError = detailError
            self.showsActions = showsActions
        }
    }

    /// 이 화면이 띄우는 모달 — 동시 표출을 타입으로 막는다(`.hilitModal(item:)` 규칙).
    /// Figma «모달을 모아봤어요» 6개 인스턴스가 5케이스로 접힌다 — 삭제 불가 두 판은
    /// 안내줄 유무만 다르므로 `remaining` 의 nil 로 표현한다.
    public enum Modal: Equatable, Sendable {
        /// 포트폴리오를 삭제하시겠어요? (435:8892)
        case deleteConfirm(remaining: Int)
        /// 포트폴리오를 삭제할 수 없어요 — 면접 진행 중 (435:8893 안내줄 없음 / 435:8894 있음)
        case deleteBlocked(remaining: Int?)
        /// 포트폴리오를 새로 업로드하시겠어요? (435:8896)
        case replaceConfirm(remaining: Int)
        /// 포트폴리오를 새로 업로드할 수 없어요 — 이번 달 기회 소진 (435:8895)
        case replaceBlocked(remaining: Int)
        /// 처리 중 (435:8897 modal/loading)
        case loading
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var profile: Profile
        public var portfolio: Portfolio
        public var reports: IdentifiedArrayOf<Report>
        /// 이번 달 남은 포트폴리오 교체·삭제 기회. 모달 안내줄 문구가 이 값에서 나온다.
        public var remainingPortfolioChanges: Int
        /// 지금 면접이 진행 중인가 — 삭제를 막는 조건(모달 «삭제할 수 없어요»).
        public var isInterviewInProgress: Bool
        /// 펼쳐진 레포트. 한 번에 하나만 펼친다.
        public var expandedReportID: Report.ID?
        /// 업로드 실패 카드 위 말풍선 노출 여부.
        public var isPortfolioTooltipPresented: Bool
        public var presentedModal: Modal?

        public init(
            profile: Profile = .placeholder,
            portfolio: Portfolio = .registered(.placeholder),
            reports: IdentifiedArrayOf<Report> = .placeholders,
            remainingPortfolioChanges: Int = 1,
            isInterviewInProgress: Bool = false,
            expandedReportID: Report.ID? = nil,
            isPortfolioTooltipPresented: Bool = false,
            presentedModal: Modal? = nil
        ) {
            self.profile = profile
            self.portfolio = portfolio
            self.reports = reports
            self.remainingPortfolioChanges = remainingPortfolioChanges
            self.isInterviewInProgress = isInterviewInProgress
            self.expandedReportID = expandedReportID
            self.isPortfolioTooltipPresented = isPortfolioTooltipPresented
            self.presentedModal = presentedModal
        }
    }

    // MARK: - Action

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            case onAppear
            case userTappedClose
            case userTappedEditProfile
            case userTappedTicketInfo
            case userTappedLogout
            case userTappedWithdraw
            /// 업로드 판(`.empty`) 또는 «다시 올리기» — 파일 선택기 진입.
            case userTappedUploadPortfolio
            case userTappedCancelUpload
            case userTappedRemovePortfolio
            /// 실패 카드 위 말풍선 탭 — 닫는다.
            case userTappedPortfolioTooltip
            /// 레포트 줄 탭 — 펼침·접힘 토글.
            case userTappedReport(id: Report.ID)
            case userTappedOpenReport(id: Report.ID)
            case userTappedRequestFeedback(id: Report.ID)
            /// 모달 왼쪽 버튼(취소·닫기).
            case userTappedModalCancel
            /// 모달 오른쪽 버튼(삭제·업로드·확인).
            case userTappedModalConfirm
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        /// 연동 전이라 비어 있다 — 프로필·레포트 조회 응답이 이 자리로 들어온다.
        public enum Inner: Sendable {}

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// 화면 닫기 요청.
            case closeRequested
            case logoutRequested
            case withdrawRequested
            /// 면접 리포트 화면으로 (Part3).
            case reportRequested(id: Report.ID)
            /// 지인 피드백 화면으로 (Part4).
            case feedbackRequested(id: Report.ID)
            /// 포트폴리오 파일 선택기 요청 — 문서 피커는 이 화면 밖 관심사다.
            case portfolioPickerRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)
            case .inner, .delegate:
                return .none
            }
        }
    }

    // MARK: - view

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            // 연동 시 프로필·포트폴리오·레포트 조회가 여기 붙는다.
            return .none

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case .userTappedEditProfile:
            // 프로필 수정 화면 시안이 Part5 에 없다 — 생기면 delegate 를 연다.
            return .none

        case .userTappedTicketInfo:
            // 티켓 안내 툴팁 시안이 Part5 에 없다.
            return .none

        case .userTappedLogout:
            return .send(.delegate(.logoutRequested))

        case .userTappedWithdraw:
            return .send(.delegate(.withdrawRequested))

        case .userTappedUploadPortfolio:
            return reduceUploadRequest(&state)

        case .userTappedCancelUpload:
            state.portfolio = .empty
            return .none

        case .userTappedRemovePortfolio:
            // 면접 중에는 지울 수 없다 — 남은 기회는 그때도 함께 보여준다(시안 두 판의 차이).
            if state.isInterviewInProgress {
                state.presentedModal = .deleteBlocked(remaining: state.remainingPortfolioChanges)
            } else {
                state.presentedModal = .deleteConfirm(remaining: state.remainingPortfolioChanges)
            }
            return .none

        case .userTappedPortfolioTooltip:
            state.isPortfolioTooltipPresented = false
            return .none

        case let .userTappedReport(id):
            state.expandedReportID = state.expandedReportID == id ? nil : id
            return .none

        case let .userTappedOpenReport(id):
            return .send(.delegate(.reportRequested(id: id)))

        case let .userTappedRequestFeedback(id):
            return .send(.delegate(.feedbackRequested(id: id)))

        case .userTappedModalCancel:
            state.presentedModal = nil
            return .none

        case .userTappedModalConfirm:
            return reduceModalConfirm(&state)
        }
    }

    /// 업로드 버튼 — 이미 등록된 포트폴리오가 있으면 «교체»라 한 달 한 번 규칙을 먼저 묻는다.
    private func reduceUploadRequest(_ state: inout State) -> Effect<Action> {
        guard case .registered = state.portfolio else {
            return .send(.delegate(.portfolioPickerRequested))
        }
        state.presentedModal = state.remainingPortfolioChanges > 0
            ? .replaceConfirm(remaining: state.remainingPortfolioChanges)
            : .replaceBlocked(remaining: state.remainingPortfolioChanges)
        return .none
    }

    /// 모달 오른쪽 버튼. 실제 삭제·교체는 서버 몫이라, 연동 전에는 모달만 닫고 화면 상태를 낙관적으로 옮긴다.
    private func reduceModalConfirm(_ state: inout State) -> Effect<Action> {
        let modal = state.presentedModal
        state.presentedModal = nil
        switch modal {
        case .deleteConfirm:
            state.portfolio = .empty
            state.remainingPortfolioChanges = max(0, state.remainingPortfolioChanges - 1)
            return .none
        case .replaceConfirm:
            return .send(.delegate(.portfolioPickerRequested))
        case .deleteBlocked, .replaceBlocked, .loading, .none:
            return .none
        }
    }
}

// MARK: - 목데이터 (연동 전 화면을 세우는 초기값)

public extension MyPageFeature.Profile {
    /// Figma «MyPage_Main» 플레이스홀더 그대로.
    static let placeholder = Self(
        name: "{재원}",
        jobGroup: "iOS",
        careerLevel: "2년차",
        remainingTickets: 3,
        email: "jaewon****@kakao.com"
    )
}

public extension MyPageFeature.PortfolioFile {
    static let placeholder = Self(name: "{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb")
}

public extension IdentifiedArray where ID == MyPageFeature.Report.ID, Element == MyPageFeature.Report {
    /// Figma «MyPage_Main» 의 레포트 세 줄 — 정상 / 포트폴리오 삭제됨 / 생성 실패.
    static var placeholders: Self {
        [
            .init(
                id: "report-normal",
                title: "iOS · 2년차 면접",
                date: "2026.07.02",
                time: "14:20",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "careers.skproptier.com/jobs/1024",
                showsActions: true
            ),
            .init(
                id: "report-portfolio-removed",
                title: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                date: "2026.07.02",
                time: "14:20",
                note: "삭제된 포트폴리오",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "직접 입력함"
            ),
            .init(
                id: "report-failed",
                title: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                date: "2026.07.02",
                time: "14:20",
                status: "생성 실패",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "-",
                detailError: "레포트 생성에 실패했어요 · 횟수는 차감되지 않았어요"
            )
        ]
    }
}

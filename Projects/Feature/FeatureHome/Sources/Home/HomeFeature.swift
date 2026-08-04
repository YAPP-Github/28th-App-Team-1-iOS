//
//  HomeFeature.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainPortfolioInterface
import DomainUserInterface
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

    /// 리포트 시트가 앉는 세 자리 — 그래버를 끌어 오간다. `phase`(서버 상태의 표시)와 직교하는
    /// **시트 높이** 축이고, 시안 프레임이 아니라 사용자가 지금 뭘 보고 있는지를 뜻한다.
    ///
    /// 시트가 다 내려가면 뒤에 깔린 면접 시작 화면이 그대로 드러난다 — 그래서 «면접 시작» 은
    /// 별도 present 가 아니라 이 축의 한 자리다(끌던 손을 놓기 전까진 되돌릴 수 있어야 해서).
    public enum SheetDetent: Equatable, Sendable {
        /// 시트가 완전히 내려가 면접 시작 화면이 드러난 자리.
        case startInterview
        /// 기본 — 인사말 그린 판 + 시트(시안 Home_Default·Home_Report).
        case report
        /// 시트가 내비바 밑까지 올라와 리포트 목록만 남은 자리.
        case expanded
    }

    /// 리포트 행 표시 모델 — 위젯② 면접 기록 한 줄. `id` 는 **세션 id** 라 그대로 리포트 상세 인자가 된다
    /// (GET /interview/sessions 의 `sessionId`).
    /// `dateText` 는 이미 포맷된 문자열이다(«7월 11일 월» 포맷은 목록을 만드는 쪽 몫).
    public struct Report: Identifiable, Equatable, Sendable {
        public let id: Int
        public let dateText: String
        public let title: String
        /// [레포트 보기] 노출 여부 — 생성 중·분석 부족·실패 세션은 열 상세가 없다
        /// (docs/work/home-account.md §3 위젯② 행 상태 표).
        public let canOpenReport: Bool

        public init(id: Int, dateText: String, title: String, canOpenReport: Bool = true) {
            self.id = id
            self.dateText = dateText
            self.title = title
            self.canOpenReport = canOpenReport
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 화면 상태 — 홈 진입 시 로드 결과(잔여·기록·포폴)가 결정한다.
        public var phase: Phase = .default
        /// 인사말에 넣는 사용자 이름 — 홈 진입 로드(`UserClient.profile`)가 덮어쓴다.
        /// 기본값은 빈 문자열이다: 사람 이름을 박아 두면 프로필 응답이 늦을 때 **모든 사용자가
        /// 남의 이름을 읽는다**. 비어 있는 동안은 뷰가 이름 없는 인사말로 떨어진다.
        public var userName: String
        /// 리포트 목록 — 최신순. 개수는 여기서 파생한다(`reports.count`), 따로 들지 않는다.
        public var reports: IdentifiedArrayOf<Report>
        /// 펼친 행 — 시안은 최신 1개가 펼쳐진 상태다. nil 이면 전부 접힘.
        public var expandedReportID: Report.ID?
        /// 시트가 지금 앉아 있는 자리. 홈에 다시 들어오면 기본으로 돌아온다(`onAppear`).
        public var sheetDetent: SheetDetent = .report
        /// 면접 시작 화면 — 시트 **뒤에 늘 깔려 있다**. present 가 아닌 이유는 `SheetDetent` 주석 참조.
        /// 잔여·포폴·변형은 홈 진입 로드가 채운다 — 진실은 탭 시점 게이트(`checkStartEligibility`) 재검증이다.
        public var startInterview: StartInterviewFeature.State
        /// dev 데이터 초기화 버튼 노출 여부 — AppFeature 가 dev 빌드에서만 켠다.
        public var showsDevReset: Bool

        public init(
            phase: Phase = .default,
            userName: String = "",
            reports: [Report] = [],
            startVariant: StartInterviewFeature.Variant = .first,
            showsDevReset: Bool = false
        ) {
            self.phase = phase
            self.userName = userName
            self.reports = IdentifiedArray(uniqueElements: reports)
            self.expandedReportID = reports.first?.id
            self.startInterview = StartInterviewFeature.State(variant: startVariant, userName: userName)
            self.showsDevReset = showsDevReset
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case startInterview(StartInterviewFeature.Action)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            // 홈 진입 로드 — 프로필·포폴은 `inner(.entryLoaded)`, 기록 목록은 `inner(.reportsLoaded)`.
            // TODO: 남은 1종(진행 중 held 세션)은 계약 확정 후(미결 6-3).
            case onAppear
            /// 시트 드래그가 끝나 자리가 정해졌다 — 판정은 뷰(`HomeSheetDrag`), 확정은 여기.
            case userSettledSheet(SheetDetent)
            /// 내비바 프로필 탭 — 마이페이지 진입 요청.
            case userTappedProfile
            /// 펼친 행의 [레포트 보기] 탭 — 리포트 상세 진입 요청.
            case userTappedReport(id: Report.ID)
            /// 리포트 행 탭 — 펼침 토글(홈 내부 상태, 화면 전환 아님).
            case userTappedReportRow(id: Report.ID)
            /// dev 데이터 초기화 탭 — 로컬·세션 데이터를 전부 지우고 앱을 처음부터 다시 태운다.
            case userTappedResetAppData
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {
            /// 홈 진입 로드 결과 — 실패한 쪽만 nil 이다(부분 실패 허용, 성공한 값은 그대로 반영).
            /// 묶음 API(미결 6-1)로 바뀌어도 갈아끼울 자리는 이 한 케이스다.
            case entryLoaded(profile: UserProfile?, portfolios: [DomainPortfolioInterface.Portfolio]?)
            /// 기록 리스트 로드 결과 — 목록과 phase 를 함께 갱신한다.
            /// nil 은 «모른다»(호출 실패) — 직전 목록을 지우지 않는다. 빈 배열은 «기록이 없다» 로 다르다.
            case reportsLoaded([Report]?)
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
            /// dev 데이터 초기화 요청 — orchestration(logout API·저장소 삭제·State 리셋·재판정)은 AppFeature.
            case appDataResetRequested
        }
    }

    /// 진입 로드 취소 식별자 — 탭을 빠르게 오갈 때 앞선 응답이 뒤늦게 덮어쓰는 걸 막는다.
    private enum CancelID { case entryLoad }

    @Dependency(\.interviewClient) var interviewClient
    @Dependency(\.portfolioClient) var portfolioClient
    @Dependency(\.userClient) var userClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 홈 밖에 다녀오면 시트는 기본 자리로 — 남의 화면에서 돌아왔는데 면접 시작이
                // 떠 있거나 목록이 펼쳐진 채면 «홈에 왔다» 는 신호가 사라진다.
                state.sheetDetent = .report
                // 첫 진입만이 아니라 **매 진입 재조회** — 포폴은 온보딩 S2·마이페이지가, 잔여·기록은
                // 면접이 바꾼다. 캐시하면 무효화 신호를 AppFeature 로 돌려야 하는데(Feature→Feature 금지)
                // 1건짜리 GET 세 번보다 비싸다. 진실은 서버(docs/work/home-account.md §3·§6).
                // 값은 지우지 않고 덮어쓰기만 한다 — 재진입마다 화면이 비면 깜빡인다.
                return .merge(
                    .run { send in
                        // 한쪽이 죽어도 다른 쪽은 그린다 — 포폴 실패로 인사말·잔여까지 날리지 않는다.
                        async let profile = try? await userClient.profile()
                        async let portfolioList = try? await portfolioClient.list()
                        await send(.inner(.entryLoaded(
                            profile: await profile,
                            portfolios: await portfolioList?.portfolios
                        )))
                    },
                    // 기록 목록은 별도 effect — 목록이 느려도 인사말·면접 시작 카드는 먼저 그린다.
                    .run { send in
                        let summaries = try? await interviewClient.reportList()
                        await send(.inner(.reportsLoaded(summaries?.map(Report.init(summary:)))))
                    }
                )
                .cancellable(id: CancelID.entryLoad, cancelInFlight: true)
            case let .view(.userSettledSheet(detent)):
                state.sheetDetent = detent
                return .none
            case .view(.userTappedProfile):
                return .send(.delegate(.profileRequested))
            case let .view(.userTappedReport(id)):
                return .send(.delegate(.reportDetailRequested(id: id)))
            case let .view(.userTappedReportRow(id)):
                // 재탭이면 접는다 — foldable 행은 홈 내부 상태다(docs/work/home-account.md §3 위젯②).
                state.expandedReportID = state.expandedReportID == id ? nil : id
                return .none
            case .view(.userTappedResetAppData):
                return .send(.delegate(.appDataResetRequested))

            case let .inner(.entryLoaded(profile, portfolios)):
                if let profile {
                    // 이름은 온보딩 전이면 비어 올 수 있다 — 그때는 앞서 그리던 값을 유지한다.
                    if let name = profile.name, !name.isEmpty {
                        state.userName = name
                        state.startInterview.userName = name
                    }
                    state.startInterview.remainingChances = profile.remainingTicketCount
                }
                if let portfolios {
                    state.startInterview.portfolio = Self.reusablePortfolio(from: portfolios)
                }
                state.startInterview.variant = Self.startVariant(
                    remainingChances: state.startInterview.remainingChances,
                    portfolio: state.startInterview.portfolio
                )
                return .none

            case let .inner(.reportsLoaded(loaded)):
                // 실패(nil)면 아무것도 건드리지 않는다 — 목록을 비우면 «기록이 없어졌다» 로 읽힌다.
                guard let reports = loaded else { return .none }
                state.reports = IdentifiedArray(uniqueElements: reports)
                state.expandedReportID = reports.first?.id
                // 기록이 있으면 **인사말을 띄운다**(`returning`) — «오랜만/최근» 을 가를 재료(마지막 방문 시각)가
                // 서버에도 목록에도 없는데 `recent` 로 두면 인사말이 영원히 안 보인다(사용자 결정 2026-08-04).
                // TODO: 마지막 방문·면접 시각 계약이 생기면 그때 `recent` 판정을 되살린다(미결 6-1).
                if reports.isEmpty {
                    state.phase = .default
                    // 펼칠 목록이 사라졌으면 확장 자리도 성립하지 않는다.
                    if state.sheetDetent == .expanded { state.sheetDetent = .report }
                } else {
                    state.phase = .report(.returning)
                }
                return .none

            case .startInterview(.delegate(.backToHomeRequested)):
                state.sheetDetent = .report
                return .none
            case .startInterview(.delegate(.startRequested)):
                // 면접 플로우는 다른 Feature 라 AppFeature 가 조립한다(Feature→Feature 금지).
                return .send(.delegate(.interviewStartRequested))
            case .startInterview(.delegate(.editInfoRequested)):
                return .send(.delegate(.interviewInfoEditRequested))
            case .startInterview:
                return .none

            case .delegate:
                return .none
            }
        }
        Scope(state: \.startInterview, action: \.startInterview) {
            StartInterviewFeature()
        }
    }
}

// MARK: - 진입 로드 → 표시값

private extension HomeFeature {
    /// «이전 정보 재사용» 카드에 걸 포폴 — MVP 는 계정당 1개지만 응답이 배열이라 첫 건을 쓴다.
    /// READY 만 고른다: PROCESSING 을 걸어 두면 시작 시점에 게이트가 `PORTFOLIO_NOT_READY` 로 뒤집는다.
    // TODO: PROCESSING 이면 3~5초 폴링해 READY 로 승격 (PortfolioClient.status — 온보딩 S2 와 같은 규칙).
    static func reusablePortfolio(
        from portfolios: [DomainPortfolioInterface.Portfolio]
    ) -> StartInterviewFeature.Portfolio? {
        portfolios
            .first { $0.status == .ready }
            .flatMap(StartInterviewFeature.Portfolio.init(portfolio:))
    }

    /// 면접 시작 카드 변형 — 잔여 0 이 최우선(소진 안내), 다음이 재사용할 포폴 유무.
    /// 서버 판정의 표시일 뿐이다 — 시작 가능 여부의 진실은 탭 시점 게이트다.
    ///
    /// **포폴 유무가 곧 «회차» 판정 키다**(docs/work/home-account.md §3 «회차 분기 판정 키»).
    /// 서버에 면접 이력 필드를 두지 않는다 — 이 분기가 묻는 건 «불러올 포폴이 있나» 이고,
    /// 포폴은 계정당 1개라 READY 한 건이 곧 재사용 대상이다. 지운 사용자가 `first` 로
    /// 떨어지는 것도 의도다 — 올릴 게 없으면 S2 부터다.
    ///
    /// **잔여를 모르면(nil) 소진이 아니다** — 프로필이 죽었을 뿐인데 «무료 횟수를 모두 사용했어요»
    /// 를 띄우면 시작 경로가 [홈으로] 하나로 막힌다. 모를 땐 포폴 유무로만 가른다.
    static func startVariant(
        remainingChances: Int?,
        portfolio: StartInterviewFeature.Portfolio?
    ) -> StartInterviewFeature.Variant {
        if let remainingChances, remainingChances <= 0 { return .exhausted }
        return portfolio == nil ? .first : .hasPortfolio
    }
}

// MARK: - 목록 응답 → 표시 행

extension HomeFeature.Report {
    /// GET /interview/sessions 한 건 → 행 하나. `id` 는 세션 id 그대로다(상세 진입 인자).
    init(summary: InterviewReportSummary) {
        self.init(
            id: summary.sessionId,
            dateText: Self.dateText(summary.interviewedAt),
            title: Self.title(for: summary),
            canOpenReport: summary.reportStatus == .ready
        )
    }

    /// 날짜 표기 «7월 11일 월» — 시안 표기를 그대로 옮긴 고정 포맷이라 기기 로케일에 흔들리지 않게 둔다.
    ///
    /// 타임존도 **KST 고정**이다 — 서버가 타임존 없는 LocalDateTime 을 주고 디코더가 그걸 KST 로 읽는데
    /// (`JSONDecoder.api`), 표시만 기기 로컬로 두면 UTC 서쪽 기기에서 하루 밀린 날짜가 뜬다
    /// (포폴 업로드일 표기와 같은 규칙 — `StartInterviewView.uploadedAtFormatter`).
    private static let interviewedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 E"
        return formatter
    }()

    private static func dateText(_ date: Date) -> String {
        interviewedAtFormatter.string(from: date)
    }

    /// 행 제목 — 생성 안 끝난/실패한 세션은 상태 안내가 제목 자리를 대신한다
    /// (docs/work/home-account.md §3 위젯② 행 상태 표).
    ///
    /// READY 는 시안처럼 «답변 한 줄 요약» 을 띄우고 싶지만 목록 응답에 그 문장이 없다 —
    /// 지금은 세션 스냅샷(직군·연차)으로 대신한다.
    // TODO: 목록 응답에 요약 문장 필드 추가 요청(미결 6-1) → 오면 이 함수만 갈아끼운다.
    private static func title(for summary: InterviewReportSummary) -> String {
        switch summary.reportStatus {
        case .ready:
            return snapshotTitle(for: summary)
        case .generating:
            return "레포트를 만들고 있어요"
        case .insufficientAnalysis:
            return "분석할 답변이 부족해 레포트를 만들지 못했어요"
        case .failed:
            return "레포트 생성에 실패했어요 · 횟수는 차감되지 않았어요"
        }
    }

    /// 세션 스냅샷 제목 — 없는 조각은 뺀다(가짜 «0년차» 를 만들지 않는다).
    private static func snapshotTitle(for summary: InterviewReportSummary) -> String {
        let pieces = [summary.jobTypeLabel, summary.careerYears.map { "\($0)년차" }].compactMap(\.self)
        return pieces.isEmpty ? "면접 레포트가 준비됐어요" : pieces.joined(separator: " · ")
    }
}

// MARK: - 시안 값

extension HomeFeature.Report {
    /// 시안(3368:17266)의 목록 5행 — **프리뷰·시안 확인 전용** 픽스처다.
    /// 실제 목록은 `inner(.reportsLoaded)` 로만 들어온다.
    public static let placeholders: [Self] = [
        .init(id: 1, dateText: "7월 11일 월", title: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해 주셨어요"),
        .init(id: 2, dateText: "7월 10일 월", title: "질문 의도를 되묻고 답변 범위를 좁혀 나갔어요"),
        .init(id: 3, dateText: "7월 10일 월", title: "경험을 시간순으로 정리해 전달했어요"),
        .init(id: 4, dateText: "7월 10일 월", title: "트레이드오프를 먼저 말하고 선택 이유를 덧붙였어요"),
        .init(id: 5, dateText: "7월 10일 월", title: "성능 개선 결과를 지표로 설명했어요")
    ]

    /// 상태가 섞인 목록 — 준비된 행 2개 + 생성 중·분석 부족·실패 각 1개.
    /// 준비 안 된 행은 제목 자리가 상태 문구이고 [레포트 보기] 가 없다(`canOpenReport: false`).
    /// 제목 문구는 `Report.title(for:)` 이 만드는 값과 같게 맞춰 뒀다 — **프리뷰 전용** 픽스처다.
    public static let statusPlaceholders: [Self] = [
        .init(id: 1, dateText: "7월 11일 토", title: "백엔드 개발자 · 3년차"),
        .init(id: 2, dateText: "7월 10일 금", title: "백엔드 개발자 · 3년차"),
        .init(id: 3, dateText: "7월 9일 목", title: "레포트를 만들고 있어요", canOpenReport: false),
        .init(
            id: 4,
            dateText: "7월 8일 수",
            title: "분석할 답변이 부족해 레포트를 만들지 못했어요",
            canOpenReport: false
        ),
        .init(
            id: 5,
            dateText: "7월 7일 화",
            title: "레포트 생성에 실패했어요 · 횟수는 차감되지 않았어요",
            canOpenReport: false
        )
    ]
}

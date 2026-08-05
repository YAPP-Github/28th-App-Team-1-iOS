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

    /// 리포트 행 표시 모델 — 위젯② 면접 기록 한 줄. 목록 응답(`InterviewReportSummary`)에서 만든다.
    /// `dateText` 는 이미 포맷된 문자열이다(«7월 11일 월» 포맷은 `init(summary:)` 몫).
    ///
    /// **`id` 는 세션 id** 다 — [레포트 보기] 가 그대로 리포트 상세(`ReportFeature.State(sessionId:)`)를
    /// 여는 열쇠라 표시용 UUID 를 따로 만들면 매핑 표가 하나 더 생긴다.
    public struct Report: Identifiable, Equatable, Sendable {
        public let id: Int
        public let dateText: String
        public let title: String

        public init(id: Int, dateText: String, title: String) {
            self.id = id
            self.dateText = dateText
            self.title = title
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
        /// dev 진입점 노출 여부 — AppFeature 가 dev 빌드에서만 켠다 (온보딩 본체 통합 전 임시 진입).
        public var showsOnboardingEntry: Bool
        /// dev 디버그 로그아웃 버튼 노출 여부 — AppFeature 가 dev 빌드에서만 켠다.
        public var showsDebugLogout: Bool

        public init(
            phase: Phase = .default,
            userName: String = "",
            reports: [Report] = [],
            startVariant: StartInterviewFeature.Variant = .first,
            showsOnboardingEntry: Bool = false,
            showsDebugLogout: Bool = false
        ) {
            self.phase = phase
            self.userName = userName
            self.reports = IdentifiedArray(uniqueElements: reports)
            self.expandedReportID = reports.first?.id
            self.startInterview = StartInterviewFeature.State(variant: startVariant, userName: userName)
            self.showsOnboardingEntry = showsOnboardingEntry
            self.showsDebugLogout = showsDebugLogout
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case startInterview(StartInterviewFeature.Action)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            // 홈 진입 로드 — 프로필·포폴(`inner(.entryLoaded)`) + 기록 리스트(`inner(.reportsLoaded)`).
            // TODO: 남은 1종(진행 중 세션 → 위젯① [이어서 진행])은 계약 확정 후(미결 6-3).
            case onAppear
            /// 시트 드래그가 끝나 자리가 정해졌다 — 판정은 뷰(`HomeSheetDrag`), 확정은 여기.
            case userSettledSheet(SheetDetent)
            /// 스크롤 안내 문구 탭 — 끌지 않고 바로 면접 시작 자리로 보낸다.
            case userTappedStartInterview
            /// 내비바 프로필 탭 — 마이페이지 진입 요청.
            case userTappedProfile
            /// 펼친 행의 [레포트 보기] 탭 — 리포트 상세 진입 요청. `id` 가 곧 세션 id 다.
            case userTappedReport(id: Report.ID)
            /// 리포트 행 탭 — 펼침 토글(홈 내부 상태, 화면 전환 아님).
            case userTappedReportRow(id: Report.ID)
            /// dev 진입 버튼 탭 — 온보딩 시작 요청.
            case userTappedOnboarding
            /// dev 디버그 로그아웃 탭 — 세션·토큰·draft 전체 삭제 요청.
            case userTappedLogout
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        /// `@CasePathable` — 테스트가 `\.inner.reportsLoaded` 처럼 케이스 키패스로 받는다
        /// (`@Reducer` 는 `Action` 까지만 붙여 준다 — 그 안의 enum 은 직접 달아야 한다).
        @CasePathable
        public enum Inner: Sendable {
            /// 홈 진입 로드 결과 — 실패한 쪽만 nil 이다(부분 실패 허용, 성공한 값은 그대로 반영).
            /// 묶음 API(미결 6-1)로 바뀌어도 갈아끼울 자리는 이 한 케이스다.
            case entryLoaded(profile: UserProfile?, portfolios: [DomainPortfolioInterface.Portfolio]?)
            /// 기록 리스트 로드 결과 — 목록과 phase 를 함께 갱신한다. 표시 모델 변환은 리듀서 몫이다
            /// (`entryLoaded` 와 같은 규칙 — 도메인 모델을 그대로 싣는다). 실패하면 오지 않는다.
            case reportsLoaded([InterviewReportSummary])
        }

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Sendable {
            /// 마이페이지 진입 요청 — 홈 밖 화면이라 조립은 AppFeature (Feature→Feature 금지).
            case profileRequested
            /// 리포트 상세 진입 요청 — 리포트 뷰는 홈 밖이라 조립은 AppFeature.
            case reportDetailRequested(sessionId: Int)
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
                // 첫 진입만이 아니라 **매 진입 재조회** — 포폴은 온보딩 S2·마이페이지가, 잔여는 면접이
                // 바꾼다. 캐시하면 무효화 신호를 AppFeature 로 돌려야 하는데(Feature→Feature 금지)
                // 1건짜리 GET 두 번보다 비싸다. 진실은 서버(docs/work/home-account.md §3·§6).
                // 값은 지우지 않고 덮어쓰기만 한다 — 재진입마다 화면이 비면 깜빡인다.
                return .run { send in
                    // 한쪽이 죽어도 다른 쪽은 그린다 — 포폴 실패로 인사말·잔여까지 날리지 않는다.
                    async let profile = try? await userClient.profile()
                    async let portfolios = try? await portfolioClient.list()
                    async let reports = try? await interviewClient.reportList()
                    await send(.inner(.entryLoaded(profile: await profile, portfolios: await portfolios)))
                    // 목록은 **성공했을 때만** 올린다 — 빈 배열이 «기록 없음»(phase 를 `.default` 로
                    // 되돌린다) 이라, 실패를 빈 배열로 뭉개면 목록이 있는 사용자의 시트가 비어 버린다.
                    if let reports = await reports {
                        await send(.inner(.reportsLoaded(reports)))
                    }
                }
                .cancellable(id: CancelID.entryLoad, cancelInFlight: true)
            case let .view(.userSettledSheet(detent)):
                state.sheetDetent = detent
                return .none
            case .view(.userTappedStartInterview):
                state.sheetDetent = .startInterview
                return .none
            case .view(.userTappedProfile):
                return .send(.delegate(.profileRequested))
            case let .view(.userTappedReport(id)):
                return .send(.delegate(.reportDetailRequested(sessionId: id)))
            case let .view(.userTappedReportRow(id)):
                // 재탭이면 접는다 — foldable 행은 홈 내부 상태다(docs/work/home-account.md §3 위젯②).
                state.expandedReportID = state.expandedReportID == id ? nil : id
                return .none
            case .view(.userTappedOnboarding):
                return .send(.delegate(.onboardingRequested))
            case .view(.userTappedLogout):
                return .send(.delegate(.logoutRequested))

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

            case let .inner(.reportsLoaded(summaries)):
                // 최신순으로 다시 세운다 — 응답 순서는 계약에 없고, 시안은 맨 위가 최근 면접이다
                // (펼치는 행도 «최신 1개» 라 순서가 흔들리면 엉뚱한 행이 펼쳐진다).
                let reports = summaries
                    .sorted { $0.interviewedAt > $1.interviewedAt }
                    .map(Report.init(summary:))
                state.reports = IdentifiedArray(uniqueElements: reports)
                state.expandedReportID = reports.first?.id
                // 인사말 변형(returning/recent) 판정 재료는 목록에 없다 — 목록 유무만 반영하고 변형은 유지한다.
                switch (reports.isEmpty, state.phase) {
                case (true, _):
                    state.phase = .default
                    // 펼칠 목록이 사라졌으면 확장 자리도 성립하지 않는다.
                    if state.sheetDetent == .expanded { state.sheetDetent = .report }
                case (false, .report):
                    break
                case (false, .default):
                    state.phase = .report(.recent)
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

// MARK: - 목록 응답 → 행

extension HomeFeature.Report {
    /// 기록 리스트 응답 한 건 → 행 하나.
    ///
    /// 제목은 **세션 스냅샷(직군·연차)** 으로 세운다 — 목록 응답엔 리포트 한 줄 요약(`headline`)이 없고
    /// 그건 세션별 상세(`InterviewReportClient.report`)에만 있다. 행마다 상세를 때리면 목록 한 번에
    /// N+1 호출이 붙는다. 표기는 DS «card» 의 «직군명 · n년차 면접» 규칙을 따른다.
    // TODO: 목록 응답에 headline 이 생기면 제목을 그 값으로 바꾼다 (시안 문구가 요약문 — 서버 협의).
    // TODO: 생성 실패·삭제된 포폴 표기(`reportStatus`·`portfolioDeleted`)는 홈 시안에 자리가 없어
    //       흘리지 않는다 — 시안 확정 후 행에 태그를 붙인다(docs/work/home-account.md §6).
    init(summary: InterviewReportSummary) {
        self.init(
            id: summary.sessionId,
            dateText: Self.dateFormatter.string(from: summary.interviewedAt),
            title: Self.title(for: summary)
        )
    }

    /// 행 날짜 «7월 11일 월» — 시안 표기를 그대로 옮긴 고정 포맷이라 로케일에 흔들리지 않게 둔다.
    ///
    /// 타임존도 **KST 고정**이다 — 서버가 타임존 없는 LocalDateTime 을 주고 디코더가 그걸 KST 로
    /// 읽는데(`JSONDecoder.api`), 표시만 기기 로컬로 두면 UTC 서쪽 기기에서 하루 밀린 날짜가 뜬다
    /// (「면접 시작」 카드의 업로드일 표기와 같은 규칙).
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 E"
        return formatter
    }()

    /// 제목 «백엔드 개발자 · 3년차 면접» — 없는 조각은 뺀다(가짜 «0년차» 를 만들지 않는다).
    /// 연차 표기(0 = 신입, 상한 10 = «10년 이상»)는 온보딩 연차 휠(`CareerOption.label`)과 같은 규칙인데
    /// 그 타입은 다른 Feature 라 가져오지 못한다(Feature→Feature 금지) — 규칙만 옮겨 적는다.
    private static func title(for summary: InterviewReportSummary) -> String {
        let head = [summary.jobTypeLabel, summary.careerYears.map(Self.careerText)]
            .compactMap { $0 }
            .joined(separator: " · ")
        return head.isEmpty ? "면접 리포트" : "\(head) 면접"
    }

    private static func careerText(_ years: Int) -> String {
        switch years {
        case ..<1: "신입"
        case 10...: "10년 이상"
        default: "\(years)년차"
        }
    }
}

// MARK: - 시안 값

extension HomeFeature.Report {
    /// 시안(3368:17266)의 목록 5행 — **프리뷰·시안 확인 전용** 픽스처다.
    /// 실제 목록은 `inner(.reportsLoaded)` 로만 들어온다(id 도 거기선 세션 id 다).
    public static let placeholders: [Self] = [
        .init(id: 1, dateText: "7월 11일 월", title: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해 주셨어요"),
        .init(id: 2, dateText: "7월 10일 월", title: "질문 의도를 되묻고 답변 범위를 좁혀 나갔어요"),
        .init(id: 3, dateText: "7월 10일 월", title: "경험을 시간순으로 정리해 전달했어요"),
        .init(id: 4, dateText: "7월 10일 월", title: "트레이드오프를 먼저 말하고 선택 이유를 덧붙였어요"),
        .init(id: 5, dateText: "7월 10일 월", title: "성능 개선 결과를 지표로 설명했어요")
    ]

    /// 프리뷰 전용 목록 스텁 — 진입 재조회를 «실패» 로 두어 위 픽스처(또는 «기록 없음»)를 지킨다.
    /// 프리뷰 클라이언트(`InterviewClient.previewValue`)는 1행을 주므로, 안 막으면 시안 5행이
    /// 그 1행으로 갈리고 `HomeDefault` 프리뷰마저 report phase 로 넘어간다.
    public static let previewKeepingFixtures: @Sendable () async throws -> [InterviewReportSummary] = {
        throw CancellationError()
    }
}

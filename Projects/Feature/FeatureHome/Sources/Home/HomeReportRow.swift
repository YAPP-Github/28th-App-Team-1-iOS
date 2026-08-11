//
//  HomeReportRow.swift
//  FeatureHomeImplementation
//
//  Created by EunseoKim on 26/08/07.
//

import DomainInterviewInterface
import Foundation

// `HomeFeature.Report`(위젯② 행 모델)의 응답 매핑과 시안 픽스처 — 리듀서 본체와 갈라 둔 자리다.
// 여기 있는 건 전부 «목록 응답 한 건 → 화면 한 줄» 규칙이고, 리듀서 분기와 섞이면 둘 다 안 읽힌다.

// MARK: - 목록 응답 → 표시 행

extension HomeFeature.Report {
    /// GET /interview/sessions 한 건 → 행 하나. `id` 는 세션 id 그대로다(상세 진입 인자).
    ///
    /// **GENERATING 은 행을 만들지 않는다**(nil) — 채점이 끝나기 전 세션은 목록에서 빼기로 확정했다
    /// (사용자 결정 2026-08-04, PRD 위젯② 행 상태 표에 없던 자리). 홈은 폴링하지 않으므로
    /// 생성이 끝난 행은 다음 홈 진입 재조회 때 나타난다.
    init?(summary: InterviewReportSummary) {
        guard summary.reportStatus != .generating else { return nil }
        let isFailed = summary.reportStatus == .failed
        self.init(
            id: summary.sessionId,
            dateText: Self.dateText(summary.interviewedAt),
            title: Self.title(for: summary),
            subtitle: isFailed ? Self.failureSubtitle : nil,
            // 실패 세션은 열 상세가 없다. INSUFFICIENT_ANALYSIS 는 채점된 카드만이라도 있는
            // 리포트라 READY 와 같은 행이다(사용자 결정 2026-08-04).
            canOpenReport: !isFailed
        )
    }

    /// 날짜 표기 «7월 11일 월» — 시안 표기를 그대로 옮긴 고정 포맷이라 기기 로케일에 흔들리지 않게 둔다.
    ///
    /// 타임존도 **KST 고정**이다 — 서버가 타임존 없는 LocalDateTime 을 주고 디코더가 그걸 KST 로 읽는데
    /// (`JSONDecoder.api`), 표시만 기기 로컬로 두면 UTC 서쪽 기기에서 하루 밀린 날짜가 뜬다.
    /// 읽는 쪽과 쓰는 쪽이 같은 가정을 써야 한다(백엔드와 타임존 계약 확정 시 두 곳을 같이 고친다).
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

    /// 생성 실패 행 보조 문구 — 실패해도 이용권은 안 깎인다는 게 이 행이 전할 전부다(시안 2026-08-05).
    static let failureSubtitle = "이용권 횟수는 차감되지 않아요"

    /// 행 제목 — 실패만 상태 문구고, 그 밖에는 시안대로 서버 «답변 한 줄 요약»(`summary.title`)이다.
    /// 그 필드는 목록 응답에 뒤늦게 붙었으므로(2026-08-07) 비어 오면 세션 스냅샷(직군·연차)으로 떨어진다
    /// — fallback 이 남는 건 필드 이전에 만들어진 과거 세션 때문이다.
    private static func title(for summary: InterviewReportSummary) -> String {
        guard summary.reportStatus != .failed else { return "레포트 생성에 실패했어요" }
        let summarized = summary.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return summarized.isEmpty ? snapshotTitle(for: summary) : summarized
    }

    /// 세션 스냅샷 제목 — 없는 조각은 뺀다(가짜 «0년차» 를 만들지 않는다).
    /// 연차 표기(0 = 신입, 상한 10 = «10년 이상»)는 온보딩 연차 휠(`CareerOption.label`)과 같은 규칙인데
    /// 그 타입은 다른 Feature 라 가져오지 못한다(Feature→Feature 금지) — 규칙만 옮겨 적는다.
    private static func snapshotTitle(for summary: InterviewReportSummary) -> String {
        let pieces = [summary.jobTypeLabel, summary.careerYears.map(Self.careerText)].compactMap(\.self)
        return pieces.isEmpty ? "면접 레포트가 준비됐어요" : pieces.joined(separator: " · ")
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

    /// 세션 스냅샷 제목 목록 — 요약 문장이 없는 과거 세션 행이 어떻게 보이는지 확인하는 **프리뷰 전용** 픽스처.
    /// 제목은 `Report.title(for:)` 의 fallback 갈래가 만드는 값과 같게 맞췄다(직군 · 연차).
    public static let snapshotPlaceholders: [Self] = [
        .init(id: 1, dateText: "7월 11일 토", title: "백엔드 개발자 · 3년차"),
        .init(id: 2, dateText: "7월 10일 금", title: "프론트엔드 개발자 · 1년차"),
        .init(id: 3, dateText: "7월 9일 목", title: "백엔드 개발자"),
        .init(
            id: 4,
            dateText: "7월 8일 수",
            title: "레포트 생성에 실패했어요",
            subtitle: failureSubtitle,
            canOpenReport: false
        )
    ]

    /// 프리뷰 전용 목록 스텁 — 진입 재조회를 «실패» 로 두어 위 픽스처(또는 «기록 없음»)를 지킨다.
    /// 프리뷰 클라이언트(`InterviewClient.previewValue`)는 1행을 주므로, 안 막으면 시안 5행이
    /// 그 1행으로 갈리고 `HomeDefault` 프리뷰마저 report phase 로 넘어간다.
    public static let previewKeepingFixtures: @Sendable () async throws -> [InterviewReportSummary] = {
        throw CancellationError()
    }
}

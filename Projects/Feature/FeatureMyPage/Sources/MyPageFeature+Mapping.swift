//
//  MyPageFeature+Mapping.swift
//  FeatureMyPage
//
//  Created by 서정원 on 26/08/08.
//

import DomainInterviewInterface
import DomainPortfolioInterface
import DomainUserInterface
import Foundation

// 서버 응답 → 표시 모델. 표시 규칙의 단일 소스 — 스펙 ⑤(docs/superpowers/specs/2026-08-08-mypage-api-design.md).

extension MyPageFeature.Profile {
    init(profile: UserProfile) {
        self.init(
            name: profile.name ?? "",
            jobGroup: profile.jobRoleLabel ?? "",
            careerLevel: profile.careerYears.map { "\($0)년차" } ?? "",
            remainingTickets: profile.remainingTicketCount,
            email: profile.email ?? "-",
            provider: profile.provider
        )
    }
}

extension MyPageFeature.PortfolioFile {
    init(portfolio: Portfolio) {
        self.init(
            id: portfolio.portfolioId,
            name: portfolio.fileName ?? "",
            date: portfolio.uploadedAt.map(MyPageFormat.date),
            size: portfolio.fileSize.map(MyPageFormat.size)
        )
    }
}

extension MyPageFeature.Portfolio {
    /// 목록 → 포폴 칸. `.uploaded`/`.uploading(progress > 0)` 은 로컬 업로드 전용이라 만들지 않는다 —
    /// 조회 시점 PROCESSING 은 진행률을 모르므로 progress 0 으로 «처리 중» 사실만 그린다 —
    /// 이 판을 본 리듀서가 상태 폴링을 이어받는다(MyPageReducer 의 `entryLoaded`).
    init(list: PortfolioList) {
        guard let first = list.portfolios.first, first.status != .cancelled else {
            self = .empty
            return
        }
        let file = MyPageFeature.PortfolioFile(portfolio: first)
        switch first.status {
        case .processing:
            self = .uploading(file, progress: 0)
        case .failedFile, .failedSystem:
            self = .failed(file)
        case .ready, .cancelled, nil:
            self = .registered(file)
        }
    }
}

extension MyPageFeature.Report {
    /// GET /interview/sessions 한 건 → 행 하나. GENERATING 은 행을 만들지 않는다(홈과 같은 결정).
    init?(summary: InterviewReportSummary) {
        guard summary.reportStatus != .generating else { return nil }
        let isFailed = summary.reportStatus == .failed
        let canOpen = !isFailed
        self.init(
            id: summary.sessionId,
            title: isFailed || summary.portfolioDeleted
                ? (summary.portfolioFileName ?? Self.snapshotTitle(summary))
                : Self.snapshotTitle(summary),
            date: MyPageFormat.date(summary.interviewedAt),
            time: MyPageFormat.time(summary.interviewedAt),
            note: summary.portfolioDeleted ? "삭제된 포트폴리오" : nil,
            status: isFailed ? "생성 실패" : nil,
            jobLevel: Self.pieces(summary, yearsSuffix: "년") ?? "-",
            portfolioName: summary.portfolioFileName ?? "-",
            // jd_source(url|text) 는 PRD 계약이나 목록 응답에 아직 없다 — 올 때까지 nil 은 "-" (스펙 ⑩).
            jobDescription: summary.jdUrl ?? "-",
            detailError: isFailed ? "리포트 생성에 실패했어요 · 횟수는 차감되지 않았어요" : nil,
            canOpenReport: canOpen,
            canRequestFeedback: canOpen && summary.feedbackAvailable
        )
    }

    /// 접힘 제목 — «직군 · N년차 면접», 없는 조각은 뺀다(가짜 «0년차» 를 만들지 않는다 — 홈 규칙).
    private static func snapshotTitle(_ summary: InterviewReportSummary) -> String {
        pieces(summary, yearsSuffix: "년차").map { $0 + " 면접" } ?? "면접 리포트"
    }

    private static func pieces(_ summary: InterviewReportSummary, yearsSuffix: String) -> String? {
        let pieces = [summary.jobTypeLabel, summary.careerYears.map { "\($0)\(yearsSuffix)" }]
            .compactMap(\.self)
        return pieces.isEmpty ? nil : pieces.joined(separator: " · ")
    }
}

/// 표시 포맷 — 로케일·타임존을 KST·en_US_POSIX 로 고정한다. 서버가 타임존 없는 LocalDateTime 을 주고
/// 디코더가 KST 로 읽으므로, 표시만 기기 로컬이면 UTC 서쪽 기기에서 하루 밀린다(홈·StartInterview 와 같은 규칙).
enum MyPageFormat {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    /// «14:20» — 시간 표기의 첫 선례(스펙 ⑤).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func date(_ date: Date) -> String { dateFormatter.string(from: date) }
    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }

    /// 용량 «3.2mb» — 시안 소문자 단위·MB 기준(StartInterview `sizeText` 와 같은 규칙).
    static func size(_ byteCount: Int) -> String {
        String(format: "%.1fmb", Double(byteCount) / 1_048_576)
    }
}

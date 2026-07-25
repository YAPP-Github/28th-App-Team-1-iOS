//
//  HighlightContext.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import DomainInterviewReportInterface
import Foundation

/// 하이라이트 상세 시트의 입력. 서버 카드·구간에서 시트가 쓸 값만 뽑아 조립한다.
///
/// Domain 이 아니라 이 Feature 에 두는 이유: 서버 계약을 정규화하는 타입(`HighlightTone`)과 달리
/// 이건 시트 화면의 구성물이다 — Domain 이 화면 구성을 알면 안 된다 (정의서 §9-2).
///
/// `keyword`·`followUpQuestions`·`evidenceAt` 는 서버 확장(§9-1) 전까지 비어 온다.
/// 비면 그 블록을 렌더하지 않는데, 이는 PRD 의 "유의미한 질문이 없으면 depth 2 생략" 과 같은 동작이라
/// 확장 전후로 코드 경로가 갈리지 않는다.
public struct HighlightContext: Equatable, Sendable {
    /// 하이라이트된 문장 원문.
    public let sentence: String
    public let tone: HighlightTone
    /// 진단 설명 (서버 소유 문구).
    public let analysis: String?
    /// 행동형 키워드 태그 — 🔴 확장 전 nil.
    public let keyword: String?
    /// 다음 대비 질문 최대 2개 — 🔴 확장 전 빈 배열.
    public let followUpQuestions: [String]
    /// 근거 구간 시작 시각(초) — 🔴 확장 전 nil.
    public let evidenceAt: TimeInterval?

    public init(
        sentence: String,
        tone: HighlightTone,
        analysis: String?,
        keyword: String? = nil,
        followUpQuestions: [String] = [],
        evidenceAt: TimeInterval? = nil
    ) {
        self.sentence = sentence
        self.tone = tone
        self.analysis = analysis
        self.keyword = keyword
        self.followUpQuestions = followUpQuestions
        self.evidenceAt = evidenceAt
    }

    /// 카드와 구간에서 조립한다. 서버 인덱스가 대본과 어긋나 문장을 못 자르면 nil —
    /// 호출부는 시트를 열지 않는다.
    public init?(card: InterviewReportCard, span: HighlightSpan) {
        guard let sentence = card.sentence(for: span) else { return nil }
        self.init(
            sentence: sentence,
            tone: span.highlightTone,
            analysis: span.analysis
        )
    }
}

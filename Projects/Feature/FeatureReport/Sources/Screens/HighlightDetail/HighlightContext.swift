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
/// 문장만이 아니라 **대본 전체**를 들고 있다 — 시트의 «분석 내용» 은 강조 구간 앞뒤 문맥을
/// 흐린 색으로 함께 보여준다(Figma 443:7324). 문장만 넘기면 그 문맥이 사라진다.
///
/// `keyword`·`followUpQuestions`·`intentReview`·`evidenceAt` 는 서버 확장(§9-1) 전까지 비어 온다.
/// 비면 그 블록을 렌더하지 않는데, 이는 PRD 의 "유의미한 질문이 없으면 depth 2 생략" 과 같은 동작이라
/// 확장 전후로 코드 경로가 갈리지 않는다.
public struct HighlightContext: Equatable, Sendable {
    /// «질문 의도 ↔ 내 답변» 대조 — 부정 톤 시트의 다음 대비 블록(Figma 443:7414).
    ///
    /// 세 값을 낱개 옵셔널로 두지 않고 한 덩이로 묶는다 — 하나만 비면 «질문이 물은 것과 내가 말한 것을
    /// 나란히 놓는다» 는 블록의 의미가 사라져서, 부분만 온 상태를 표현할 이유가 없다.
    public struct IntentReview: Equatable, Sendable {
        /// 질문이 실제로 묻고 있던 것 — 시안 «장애 원인을 좁혀가는 순서».
        public let intent: String
        /// 원 질문 문구 — 시안 «Q. 앱 업데이트 이후 성능이 저하되었습니다…».
        public let question: String
        /// 내 답변이 실제로 말한 주제 — 시안 «팀 내 신뢰와 성향».
        public let answerTopic: String

        public init(intent: String, question: String, answerTopic: String) {
            self.intent = intent
            self.question = question
            self.answerTopic = answerTopic
        }
    }

    /// 하이라이트가 속한 답변 대본 전체.
    public let transcript: String
    /// 강조 구간 — 톤·진단 문구도 여기서 나온다.
    public let span: HighlightSpan
    /// 행동형 키워드 태그 — 🔴 확장 전 nil.
    public let keyword: String?
    /// 다음 대비 질문 최대 2개 — 🔴 확장 전 빈 배열.
    public let followUpQuestions: [String]
    /// 부정 톤 대조 블록 — 🔴 확장 전 nil.
    public let intentReview: IntentReview?
    /// 근거 구간 시작 시각(초). 서버 `evidenceStartAt` 이나 구간 대본에서 얻는다 —
    /// 둘 다 없으면 nil 이고 영상을 처음부터 재생한다.
    public let evidenceAt: TimeInterval?

    public init(
        transcript: String,
        span: HighlightSpan,
        keyword: String? = nil,
        followUpQuestions: [String] = [],
        intentReview: IntentReview? = nil,
        evidenceAt: TimeInterval? = nil
    ) {
        self.transcript = transcript
        self.span = span
        self.keyword = keyword
        self.followUpQuestions = followUpQuestions
        self.intentReview = intentReview
        self.evidenceAt = evidenceAt
    }

    /// 카드와 구간에서 조립한다. 서버 인덱스가 대본과 어긋나 문장을 못 자르면 nil —
    /// 호출부는 시트를 열지 않는다.
    public init?(card: InterviewReportCard, span: HighlightSpan) {
        guard let transcript = card.transcript, card.sentence(for: span) != nil else { return nil }
        self.init(
            transcript: transcript,
            span: span,
            evidenceAt: card.evidenceTime(for: span)
        )
    }

    public var tone: HighlightTone { span.highlightTone }

    /// 진단 설명 (서버 소유 문구).
    public var analysis: String? { span.analysis }

    /// 강조된 문장 원문. 조립 시점에 인덱스를 검증하므로 여기서는 빈 문자열로만 방어한다.
    public var sentence: String {
        let characters = Array(transcript)
        guard span.startIndex >= 0,
              span.endIndex > span.startIndex,
              span.endIndex <= characters.count
        else { return "" }
        return String(characters[span.startIndex..<span.endIndex])
    }
}

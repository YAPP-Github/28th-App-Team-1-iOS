//
//  InterviewReportFixtures.swift
//  DomainInterviewReportTesting
//
//  Created by EunSeo on 26/07/25.
//

import DomainInterviewReportInterface
import Foundation

/// 리포트 화면 개발·테스트용 고정 응답 모음.
/// 화면 분기(정상/채점중/분석부족/레드플래그/해상도낮음)마다 하나씩 둬서
/// 프리뷰·TestStore·Example 앱이 같은 데이터를 공유한다.
public enum InterviewReportFixtures {
    /// 영상까지 살아 있는 정상 보고서 — 플레이어 경로 확인용.
    public static var ready: InterviewReport {
        InterviewReport(
            status: .ready,
            headline: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해주셨어요.",
            video: InterviewReportVideo(
                url: "https://example.com/interview/1.mp4",
                expired: false,
                expiresAt: Date(timeIntervalSince1970: 1_782_172_800)
            ),
            cards: [strongCard, improveCard],
            script: fullScript,
            guestFeedback: nil
        )
    }

    /// 채점 진행 중 — 나머지 필드가 전부 nil 로 온다(폴링 대상).
    public static var generating: InterviewReport {
        InterviewReport(
            status: .generating,
            headline: nil,
            video: nil,
            cards: nil,
            script: nil,
            guestFeedback: nil
        )
    }

    /// 분석 부족 — 채점된 범위의 카드만 내려온다.
    public static var insufficientAnalysis: InterviewReport {
        InterviewReport(
            status: .insufficientAnalysis,
            headline: "이번 면접의 답변이 충분하지 않아요. 다음 면접 연습 때는 조금 더 충분한 답변을 말씀해주세요.",
            video: InterviewReportVideo(url: nil, expired: true, expiresAt: nil),
            cards: [lowResolutionCard],
            guestFeedback: nil
        )
    }

    /// 카드 레드플래그 3건 — 툴팁이 배열을 전부 잇는지 확인용(모순 계열 + 무결점 + 기타).
    /// 레드플래그는 보고서 단위 필드가 없다 — 걸린 카드의 `cardRedFlagNotices` 로만 온다.
    public static var withRedFlags: InterviewReport {
        InterviewReport(
            status: .ready,
            headline: "이번 면접에서는 캐시 도입 결정과 장애 대응 경험을 중심으로 이야기를 나눴어요.",
            video: InterviewReportVideo(
                url: "https://example.com/interview/2.mp4",
                expired: false,
                expiresAt: nil
            ),
            cards: [redFlaggedCard],
            guestFeedback: nil
        )
    }

    /// 해상도 낮음 카드만 있는 보고서 — 하이라이트가 없어 시트 진입 대상이 없다.
    public static var lowResolutionOnly: InterviewReport {
        InterviewReport(
            status: .ready,
            headline: "이번 면접에서는 결제 응답 속도 개선 경험을 중심으로 이야기를 나눴어요.",
            video: nil,
            cards: [lowResolutionCard],
            guestFeedback: nil
        )
    }

    /// 지인 2명이 피드백을 남긴 보고서 — 지인 피드백 섹션이 «보내기» 카드 대신 평가 목록으로 바뀐다.
    public static var withGuestFeedback: InterviewReport {
        InterviewReport(
            status: .ready,
            headline: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해주셨어요.",
            video: InterviewReportVideo(
                url: "https://example.com/interview/1.mp4",
                expired: false,
                expiresAt: Date(timeIntervalSince1970: 1_782_172_800)
            ),
            cards: [strongCard, improveCard],
            script: fullScript,
            guestFeedback: GuestFeedbackSection(
                participantCount: 2,
                guests: [firstGuest, secondGuest]
            )
        )
    }

    // MARK: - 지인

    /// 5축을 모두 채우고 코멘트 길이가 제각각인 지인 — 코멘트 펼치기 분기 확인용.
    public static var firstGuest: GuestReview {
        GuestReview(
            alias: "허자연",
            attitudeRatings: [
                GuestAttitudeRating(axis: "GAZE", level: 3, comment: "꼬리질문에서 눈빛이 흔들려서 자신감이 없어 보였어요."),
                GuestAttitudeRating(
                    axis: "EXPRESSION",
                    level: 1,
                    comment: "꼬리질문에서 눈빛이 흔들려서 자신감이 없어 보였어요. 그래서 조금 아쉬웠습니다."
                ),
                GuestAttitudeRating(axis: "POSTURE", level: 1, comment: nil),
                GuestAttitudeRating(axis: "GESTURE", level: 1, comment: nil),
                GuestAttitudeRating(axis: "VOICE", level: 3, comment: "목소리가 조금 작게 들렸어요.")
            ]
        )
    }

    /// 일부 축만 남기고 서버가 새 코드를 섞어 보낸 지인 — 화면이 모르는 축을 건너뛰는지 확인용.
    public static var secondGuest: GuestReview {
        GuestReview(
            alias: "박민주",
            attitudeRatings: [
                GuestAttitudeRating(axis: "GAZE", level: 2, comment: nil),
                GuestAttitudeRating(axis: "NEW_AXIS", level: 1, comment: "서버가 축을 늘린 경우")
            ]
        )
    }

    // MARK: - 대본 타임라인

    /// 세션 전체 발화 — 면접자 답변과 면접관 마무리 멘트가 시각 순으로 이어진 한 배열.
    /// 서버 계약 형태 보존용이다 — 진행바 칸이 턴 단위가 되면서(2026-08-07) 화면 사용처는 없다.
    /// 답변 시각은 카드 발화와 같은 축이다 — 픽스처를 쓰는 테스트가 한 시간축을 공유한다.
    public static var fullScript: [ScriptSegment] {
        [
            ScriptSegment(role: .interviewee, text: "프로파일링하니 DB 왕복이 7번 도는 N+1이 원인이었고,", startSec: 0, endSec: 3.4),
            ScriptSegment(role: .interviewee, text: "안 바뀌는 6번을 캐시로 흡수해 600ms를 깎았어요.", startSec: 3.4, endSec: 6.4),
            ScriptSegment(role: .interviewee, text: "결제가 느려서 캐시를 써서 빠르게 만들었어요.", startSec: 6.4, endSec: 9.1),
            ScriptSegment(role: .interviewee, text: "그 캐시는 팀이 원래 쓰던 것이라 저는 운영만 했어요.", startSec: 9.1, endSec: 12),
            ScriptSegment(role: .interviewer, text: "수고하셨습니다. 면접을 마치겠습니다.", startSec: 12, endSec: 14)
        ]
    }
}

// MARK: - 카드

/// 카드는 별도 extension — 한 타입 본문에 다 넣으면 길이 제한(250줄)을 넘긴다.
public extension InterviewReportFixtures {
    /// 잘함(파고들 여지) 하이라이트가 있는 카드 — 꼬리질문 판 확인용.
    static var strongCard: InterviewReportCard {
        let transcript = "프로파일링하니 DB 왕복이 7번 도는 N+1이 원인이었고, 안 바뀌는 6번을 캐시로 흡수해 600ms를 깎았어요."
        return InterviewReportCard(
            axisOrder: 1,
            depthLevel: 1,
            questionText: "결제 응답 속도를 개선하신 경험을 말씀해주세요.",
            transcript: transcript,
            highlightSpans: [
                HighlightSpan(
                    startIndex: 0,
                    endIndex: 30,
                    tone: "GOOD",
                    reason: "PROBE_WORTHY",
                    title: "구체적 수치로 원인 설명",
                    analysis: "문제부터 원인, 한계까지 스스로 짚었어요.",
                    followUpQuestions: ["그 수치는 어떤 기간을 기준으로 집계한 건가요?"],
                    startSec: 0
                )
            ],
            resolutionNotice: nil,
            cardRedFlagNotices: nil,
            questionIntentTitle: "성능 저하 인지 수준",
            questionIntent: "성능 문제를 얼마나 구체적으로 인지했는지 확인하는 질문입니다.",
            // 이 턴의 면접자 발화 — 문자 오프셋은 카드 `transcript` 기준(하이라이트와 같은 좌표계).
            scriptSegments: [
                ScriptSegment(
                    role: .interviewee,
                    text: "프로파일링하니 DB 왕복이 7번 도는 N+1이 원인이었고,",
                    startIndex: 0,
                    endIndex: 30,
                    startSec: 0,
                    endSec: 3.4
                ),
                ScriptSegment(
                    role: .interviewee,
                    text: "안 바뀌는 6번을 캐시로 흡수해 600ms를 깎았어요.",
                    startIndex: 31,
                    endIndex: 58,
                    startSec: 3.4,
                    endSec: 6.4
                )
            ]
        )
    }

    /// 개선(딴 답) 하이라이트가 있는 카드 — «질문 의도 ↔ 내 답변» 대조 판 확인용.
    static var improveCard: InterviewReportCard {
        let transcript = "결제가 느려서 캐시를 써서 빠르게 만들었어요. 그 캐시는 팀이 원래 쓰던 것이라 저는 운영만 했어요."
        return InterviewReportCard(
            axisOrder: 2,
            depthLevel: 1,
            questionText: "그 방법을 고른 이유가 무엇인가요?",
            transcript: transcript,
            highlightSpans: [
                HighlightSpan(
                    startIndex: 0,
                    endIndex: 24,
                    tone: "IMPROVE",
                    reason: "OFF_INTENT",
                    title: "질문과 다른 주제로 답변",
                    analysis: "왜 그 방법이 통했는지 원인이 빠졌어요.",
                    followUpQuestions: [],
                    startSec: 6.4,
                    answerTopicTitle: "적용 결과 나열",
                    questionIntentTitle: "선택 근거와 대안 검토",
                    questionIntent: "선택의 근거와 대안 검토를 확인하는 질문입니다."
                )
            ],
            resolutionNotice: nil,
            cardRedFlagNotices: [
                RedFlagNotice(
                    type: "CONTRADICTION",
                    message: "답변 사이에 사실관계가 엇갈린 지점이 있었어요. 실제 면접관은 이런 모순에 민감할 수 있습니다."
                )
            ],
            questionIntentTitle: "선택 근거와 대안 검토",
            questionIntent: "선택의 근거와 대안 검토를 확인하는 질문입니다.",
            scriptSegments: [
                ScriptSegment(
                    role: .interviewee,
                    text: "결제가 느려서 캐시를 써서 빠르게 만들었어요.",
                    startIndex: 0,
                    endIndex: 24,
                    startSec: 6.4,
                    endSec: 9.1
                ),
                ScriptSegment(
                    role: .interviewee,
                    text: "그 캐시는 팀이 원래 쓰던 것이라 저는 운영만 했어요.",
                    startIndex: 25,
                    endIndex: 53,
                    startSec: 9.1,
                    endSec: 12
                )
            ]
        )
    }

    /// 레드플래그 3건이 걸린 카드 — 툴팁이 배열 전부를 줄바꿈으로 잇는지 확인용.
    static var redFlaggedCard: InterviewReportCard {
        InterviewReportCard(
            axisOrder: 1,
            depthLevel: 1,
            questionText: improveCard.questionText,
            transcript: improveCard.transcript,
            highlightSpans: improveCard.highlightSpans,
            resolutionNotice: nil,
            cardRedFlagNotices: [
                RedFlagNotice(
                    type: "CONTRADICTION",
                    message: "답변 사이에 사실관계가 엇갈린 지점이 있었어요. 실제 면접관은 이런 모순에 민감할 수 있습니다."
                ),
                RedFlagNotice(
                    type: "FLAWLESS_NARRATIVE",
                    message: "포기한 것이나 아쉬운 점이 거의 언급되지 않았어요. 면접관은 비용을 아는 답변을 신뢰하는 경향이 있습니다."
                ),
                RedFlagNotice(type: "OTHER", message: "세 번째 안내 — 툴팁 세 번째 줄로 선다.")
            ],
            questionIntentTitle: improveCard.questionIntentTitle,
            questionIntent: improveCard.questionIntent,
            scriptSegments: improveCard.scriptSegments
        )
    }

    /// 해상도 낮음 카드 — 안내 문구가 있고 하이라이트는 비어 있다.
    static var lowResolutionCard: InterviewReportCard {
        InterviewReportCard(
            axisOrder: 3,
            depthLevel: 1,
            questionText: "트래픽이 몰렸을 때 어떻게 대응하셨나요?",
            transcript: "트래픽이 몰려도 잘 돌아갔어요.",
            highlightSpans: [],
            resolutionNotice: "AI가 분석을 제공하기에는 이번 질문에 대한 답변이 충분하지 않아요. "
                + "다음 면접 연습 때는 유사한 질문에 조금 더 충분한 답변을 말씀해주세요.",
            cardRedFlagNotices: nil,
            questionIntentTitle: "부하 대응 경계",
            questionIntent: "부하 상황의 대응 경계를 확인하는 질문입니다."
        )
    }
}

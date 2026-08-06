//
//  ReportVideoPlayerViewPreviews.swift
//  FeatureReport
//
//  Created by EunSeo on 26/08/07.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import Foundation
import SwiftUI

private extension InterviewReportCard {
    /// 서버 발화가 없는 카드 — 대본 토글이 사라지고 하단 스크림이 그대로 남는지 확인용.
    static var previewCardWithoutScript: InterviewReportCard {
        InterviewReportCard(
            axisOrder: 1,
            depthLevel: 1,
            questionText: "결제 응답 속도를 개선하신 경험을 말씀해주세요.",
            transcript: "프로파일링하니 DB 왕복 7번이 원인이라, 안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.",
            highlightSpans: nil,
            resolutionNotice: nil,
            cardRedFlagNotices: nil,
            questionIntent: nil,
            scriptSegments: nil
        )
    }

    /// 프리뷰용 카드 — Sources 는 Testing 타겟에 의존하지 않아 여기서 최소 재료만 만든다.
    static var previewCard: InterviewReportCard {
        let transcript = "프로파일링하니 DB 왕복 7번이 원인이라, 안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요."
        return InterviewReportCard(
            axisOrder: 1,
            depthLevel: 1,
            questionText: "결제 응답 속도를 개선하신 경험을 말씀해주세요.",
            transcript: transcript,
            highlightSpans: [
                HighlightSpan(
                    startIndex: 9,
                    endIndex: transcript.count,
                    tone: "GOOD",
                    reason: "PROBE_WORTHY",
                    title: "원인과 해결을 수치로 설명",
                    analysis: "문제를 바라보는 관점이 좋았어요.",
                    followUpQuestions: ["그 수치는 어떤 기간을 기준으로 집계한 건가요?"],
                    startSec: 4.3
                )
            ],
            resolutionNotice: nil,
            cardRedFlagNotices: nil,
            questionIntent: nil,
            // 면접관 질문이 턴 첫 문장 — 오버레이가 Q 배지로 그린다.
            scriptSegments: [
                ScriptSegment(
                    role: .interviewer,
                    text: "결제 응답 속도를 개선하신 경험을 말씀해주세요.",
                    startSec: 0,
                    endSec: 2
                ),
                ScriptSegment(
                    role: .interviewee,
                    text: "프로파일링하니 DB 왕복 7번이 원인이라,",
                    startIndex: 0,
                    endIndex: 22,
                    startSec: 2,
                    endSec: 4.3
                ),
                ScriptSegment(
                    role: .interviewee,
                    text: "안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.",
                    startIndex: 23,
                    endIndex: transcript.count,
                    startSec: 4.3,
                    endSec: 6.4
                )
            ]
        )
    }
}

#Preview("영상 플레이어 — 컨트롤") {
    ReportVideoPlayerView(
        store: Store(
            initialState: ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                cards: [.previewCard]
            )
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

#Preview("영상 플레이어 — 시트 진입(이전 화면으로 가기)") {
    ReportVideoPlayerView(
        store: Store(
            initialState: ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                cards: [.previewCard],
                entry: .highlightSheet
            )
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

#Preview("영상 플레이어 — 대본 오버레이") {
    ReportVideoPlayerView(
        store: Store(
            initialState: {
                // startAt 으로 넣어야 대본 위치(transcriptPosition)까지 그 시각으로 선다 —
                // currentTime 직접 대입은 위치를 다시 세우지 않는다.
                var state = ReportVideoPlayerFeature.State(
                    videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                    startAt: 5,
                    cards: [.previewCard, .previewCard]
                )
                state.isTranscriptVisible = true
                state.duration = 6.4
                return state
            }()
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

#Preview("영상 플레이어 — 대본 없음(토글 없이 하단 스크림)") {
    ReportVideoPlayerView(
        store: Store(
            initialState: {
                var state = ReportVideoPlayerFeature.State(
                    videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                    cards: [.previewCardWithoutScript]
                )
                // 대본을 켠 상태로 들어와도 그릴 문장이 없으면 오버레이가 뜨지 않는다.
                state.isTranscriptVisible = true
                state.duration = 30
                return state
            }()
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

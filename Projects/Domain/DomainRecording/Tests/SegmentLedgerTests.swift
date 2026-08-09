//
//  SegmentLedgerTests.swift
//  DomainRecordingTests
//
//  Created by 서정원 on 26/08/08.
//

import Foundation
import Testing

@testable import DomainRecordingImplementation

// 세그먼트 원장 순수 로직(스펙 ①) — AVFoundation 없이 누적·네이밍·세션 전환을 고정한다.
struct SegmentLedgerTests {
    private func segment(duration: Double) -> SegmentLedger.Segment {
        SegmentLedger.Segment(
            videoURL: URL(fileURLWithPath: "/tmp/v.mp4"),
            videoStartedAtHostSeconds: 0,
            videoDurationSeconds: duration,
            audio: nil
        )
    }

    @Test("begin 은 세그먼트 인덱스가 붙은 경로를 주고, append 가 누적초를 쌓는다")
    func beginAndAppendAccumulate() {
        var ledger = SegmentLedger()
        let first = ledger.begin(sessionId: 7)
        #expect(first.lastPathComponent == "interview-video-7-0.mp4")
        ledger.append(segment(duration: 60.4))
        #expect(ledger.cumulativeSeconds == 60.4)
        let second = ledger.begin(sessionId: 7)
        #expect(second.lastPathComponent == "interview-video-7-1.mp4")
    }

    @Test("다른 세션으로 begin 하면 원장이 리셋된다 — 이전 세션 세그먼트가 새 세션에 섞이지 않는다")
    func beginWithNewSessionResets() {
        var ledger = SegmentLedger()
        _ = ledger.begin(sessionId: 7)
        ledger.append(segment(duration: 30))
        let url = ledger.begin(sessionId: 8)
        #expect(ledger.segments.isEmpty)
        #expect(ledger.cumulativeSeconds == 0)
        #expect(url.lastPathComponent == "interview-video-8-0.mp4")
    }

    @Test("합성본 경로는 세션 단일 — 업로드 큐 이관 계약과 같은 이름 규칙")
    func mergedURLNaming() {
        #expect(SegmentLedger.mergedURL(sessionId: 7).lastPathComponent == "interview-recording-7.mp4")
    }
}

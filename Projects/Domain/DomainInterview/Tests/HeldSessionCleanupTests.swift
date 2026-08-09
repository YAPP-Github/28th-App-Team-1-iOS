//
//  HeldSessionCleanupTests.swift
//  DomainInterviewTests
//
//  Created by 서정원 on 26/08/09.
//

import Foundation
import Testing

@testable import DomainInterviewInterface

// 앱 사망 세션 정리 판정(스펙 ④) — App 테스트 타깃이 없어 판정만 순수 함수로 내려 고정한다.
struct HeldSessionCleanupTests {
    @Test("보관값 없음·0초(준비 이탈)·현재 프로세스 진행분은 정리 대상이 아니다")
    func nonTargets() {
        #expect(HeldSessionCleanup.target(nil) == nil)
        #expect(HeldSessionCleanup.target(HeldSession(sessionId: 1, recordedSeconds: 0, processToken: nil)) == nil)
        #expect(HeldSessionCleanup.target(
            HeldSession(sessionId: 1, recordedSeconds: 60, processToken: HeldSession.currentProcessToken)
        ) == nil)
    }

    @Test("죽은 프로세스의 진행분(>0초·토큰 불일치 또는 없음)만 정리 대상이다")
    func deadRecordedSessionIsTarget() {
        #expect(HeldSessionCleanup.target(HeldSession(sessionId: 7, recordedSeconds: 60, processToken: UUID())) == 7)
        #expect(HeldSessionCleanup.target(HeldSession(sessionId: 7, recordedSeconds: 60, processToken: nil)) == 7)
    }

    @Test("판정 후속 — RESUMABLE 은 USER_EXIT 중단, ENDED 는 로컬 정리뿐(서버가 이미 끝냈다)")
    func followupByVerdict() {
        let resumable = InterviewResumeCheck(resumeState: .resumable, startedAt: nil, elapsedSeconds: 60, status: nil)
        let ended = InterviewResumeCheck(resumeState: .ended, startedAt: nil, elapsedSeconds: nil, status: .abandoned)
        #expect(HeldSessionCleanup.followup(resumable) == .abandonUserExit)
        #expect(HeldSessionCleanup.followup(ended) == .clearAndPurge)
    }
}

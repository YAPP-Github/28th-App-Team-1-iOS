//
//  HeldSessionTests.swift
//  DomainInterviewTests
//
//  Created by 서정원 on 26/08/08.
//

import Foundation
import Testing

@testable import DomainInterviewInterface

// 프로세스 토큰 판정(스펙 ⑤) — 죽은 프로세스의 진행분(>0초) 보관값은 재개 제안 대상이 아니다.
struct HeldSessionTests {
    @Test("진행분이 있고 토큰이 현재 프로세스면 재개 가능")
    func inProcessRecordedSessionIsResumable() {
        let held = HeldSession(sessionId: 1, recordedSeconds: 60, processToken: HeldSession.currentProcessToken)
        #expect(held.isResumableInCurrentProcess)
    }

    @Test("진행분이 있는데 토큰이 다르면(죽은 프로세스) 재개 불가")
    func foreignRecordedSessionIsNotResumable() {
        let held = HeldSession(sessionId: 1, recordedSeconds: 60, processToken: UUID())
        #expect(!held.isResumableInCurrentProcess)
    }

    @Test("0초(준비 이탈 보관분)는 토큰과 무관하게 재개 가능 — 잃을 영상이 없다")
    func zeroProgressSessionIsAlwaysResumable() {
        #expect(HeldSession(sessionId: 1, recordedSeconds: 0, processToken: UUID()).isResumableInCurrentProcess)
        #expect(HeldSession(sessionId: 1, recordedSeconds: 0, processToken: nil).isResumableInCurrentProcess)
    }

    @Test("토큰 없는 구버전 저장값도 디코딩된다 — 옵셔널 하위호환")
    func legacyStoredValueDecodesWithoutToken() throws {
        let legacy = Data(#"{"sessionId":7,"recordedSeconds":42}"#.utf8)
        let held = try JSONDecoder().decode(HeldSession.self, from: legacy)
        #expect(held.sessionId == 7)
        #expect(held.processToken == nil)
        #expect(!held.isResumableInCurrentProcess)   // 진행분 있음 + 토큰 없음 = 죽은 프로세스 취급
    }

    @Test("프리뷰 보관값은 재개 가능하다 — 홈 프리뷰의 «진행 중» 변형이 필터에 걸려 사라지면 안 된다")
    func previewValueIsResumable() {
        #expect(HeldSessionStore.previewValue.load()?.isResumableInCurrentProcess == true)
    }
}

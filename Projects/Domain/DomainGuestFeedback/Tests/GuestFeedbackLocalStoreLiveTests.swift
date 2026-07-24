//
//  GuestFeedbackLocalStoreLiveTests.swift
//  DomainGuestFeedbackTests
//
//  Created by 서정원 on 26/07/24.
//

import DomainGuestFeedbackInterface
import Foundation
import Testing
@testable import DomainGuestFeedbackImplementation

struct GuestFeedbackLocalStoreLiveTests {
    /// 테스트별 격리 suite — 끝나면 지운다.
    private func withSuite(_ body: (GuestFeedbackLocalStore) -> Void) {
        let suiteName = "guest-feedback-test-\(UUID().uuidString)"
        body(.live(suiteName: suiteName))
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    @Test("deviceID 는 최초 생성 후 같은 값을 돌려준다")
    func deviceIDIsStable() {
        withSuite { store in
            let first = store.deviceID()
            let second = store.deviceID()
            #expect(!first.isEmpty)
            #expect(first == second)
        }
    }

    @Test("draft 는 저장·복원·삭제 라운드트립이 된다")
    func draftRoundTrips() {
        withSuite { store in
            let draft = GuestFeedbackDraft(
                nickname: "민지",
                ratings: ["GAZE": RatingDraft(level: 2, comment: "가끔 피해요")],
                overallFeedback: "좋았어요",
                startedEvaluation: true
            )

            #expect(store.loadDraft("tok-1") == nil)
            store.saveDraft("tok-1", draft)
            #expect(store.loadDraft("tok-1") == draft)
            store.clearDraft("tok-1")
            #expect(store.loadDraft("tok-1") == nil)
        }
    }

    @Test("draft 는 토큰별로 격리된다")
    func draftsAreIsolatedPerToken() {
        withSuite { store in
            let draft = GuestFeedbackDraft(nickname: "", ratings: [:], overallFeedback: "", startedEvaluation: false)
            store.saveDraft("tok-1", draft)
            #expect(store.loadDraft("tok-2") == nil)
        }
    }
}

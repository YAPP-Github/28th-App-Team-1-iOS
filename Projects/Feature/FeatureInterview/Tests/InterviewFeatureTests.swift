//
//  InterviewFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture
import Testing

@testable import FeatureInterviewImplementation

// 코디네이터 화면 전환 중 «세션 종료 → 리포트 대기 경유 → 상위 통보» 만 고정한다.
@MainActor
struct InterviewFeatureTests {
    @Test("세션 종료는 리포트 대기 화면을 경유하고, 홈으로 탭이 상위에 종료를 통보한다")
    func sessionFinishRoutesThroughReportPending() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(InterviewSessionFeature.State())
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        }

        await store.send(.screen(.session(.delegate(.finished)))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State())
        }
        await store.send(.screen(.reportPending(.view(.userTappedGoHome))))
        await store.receive(\.screen.reportPending.delegate.goHomeRequested)
        await store.receive(\.delegate.finished)
    }

    @Test("질문 준비 실패는 questionPrep 실패 화면으로 전환한다")
    func prepFailedRoutesToFailure() async {
        let store = TestStore(initialState: InterviewFeature.State(sessionId: 1)) {
            InterviewFeature()
        }

        await store.send(.screen(.readiness(.delegate(.prepFailed)))) {
            $0.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        }
    }
}

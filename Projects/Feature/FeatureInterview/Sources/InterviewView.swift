//
//  InterviewView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import SwiftUI

// 면접 흐름 루트 — 코디네이터의 screen 상태에 따라 하위 화면을 전면 교체한다.
public struct InterviewView: View {
    @Bindable public var store: StoreOf<InterviewFeature>

    public init(store: StoreOf<InterviewFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if let store = store.scope(state: \.screen.readiness, action: \.screen.readiness) {
                InterviewReadinessView(store: store)
            } else if let store = store.scope(state: \.screen.session, action: \.screen.session) {
                InterviewSessionView(store: store)
            } else if let store = store.scope(state: \.screen.failure, action: \.screen.failure) {
                InterviewFailureView(store: store)
            } else if let store = store.scope(state: \.screen.reportPending, action: \.screen.reportPending) {
                InterviewReportPendingView(store: store)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screenCaseID)
    }

    /// 화면 전환 애니메이션 트리거 — 케이스가 바뀔 때만 발화하도록 식별자로 축약.
    private var screenCaseID: Int {
        switch store.screen {
        case .readiness: 0
        case .session: 1
        case .failure: 2
        case .reportPending: 3
        }
    }
}

#Preview {
    InterviewView(
        store: Store(initialState: InterviewFeature.State(sessionId: 1)) {
            InterviewFeature()
        }
    )
}

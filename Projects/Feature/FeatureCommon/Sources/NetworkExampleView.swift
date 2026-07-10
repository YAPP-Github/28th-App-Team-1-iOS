//
//  NetworkExampleView.swift
//  FeatureCommonImplementation
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import DomainInterviewInterface
import SwiftUI

@ViewAction(for: NetworkExampleFeature.self)
public struct NetworkExampleView: View {
    @Bindable public var store: StoreOf<NetworkExampleFeature>

    public init(store: StoreOf<NetworkExampleFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading {
                ProgressView("불러오는 중")
            } else if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            } else {
                interviewList
            }
        }
        .onAppear { send(.onAppear) }
    }

    private var interviewList: some View {
        List(store.interviews) { interview in
            VStack(alignment: .leading) {
                Text(interview.title)
                Text(interview.createdAt, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Text(message)
            Button("다시 시도") { send(.userTappedRetry) }
        }
    }
}

#Preview {
    // Preview 는 InterviewClient.previewValue(샘플)가 자동 선택된다 — 네트워크 없음.
    NetworkExampleView(
        store: Store(initialState: NetworkExampleFeature.State()) {
            NetworkExampleFeature()
        }
    )
}

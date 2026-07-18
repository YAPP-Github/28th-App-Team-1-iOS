//
//  NetworkExampleView.swift
//  FeatureCommonImplementation
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import DomainJobInterface
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
                jobList
            }
        }
        .onAppear { send(.onAppear) }
    }

    private var jobList: some View {
        List(store.jobs) { job in
            VStack(alignment: .leading) {
                Text(job.label)
                Text(job.jobRole)
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
    // Preview 는 JobClient.previewValue(샘플)가 자동 선택된다 — 네트워크 없음.
    NetworkExampleView(
        store: Store(initialState: NetworkExampleFeature.State()) {
            NetworkExampleFeature()
        }
    )
}

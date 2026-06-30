//
//  ActivityView.swift
//  ActivityFeature
//
//  Created by EunseoKim on 5/27/26.
//

import DomainActivityInterface
import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct ActivityView: View {
    @Bindable var store: StoreOf<ActivityFeature>

    public init(store: StoreOf<ActivityFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Activity")
                .toolbar {
                    if !store.items.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Clear") { store.send(.clearAllTapped) }
                        }
                    }
                }
                .onAppear { store.send(.onAppear) }
                .onDisappear { store.send(.onDisappear) }
                .alert(
                    store.errorMessage ?? "",
                    isPresented: Binding(
                        get: { store.errorMessage != nil },
                        set: { if !$0 { store.send(.alertDismissed) } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.items.isEmpty {
            ProgressView()
        } else if store.items.isEmpty {
            ContentUnavailableView(
                "No activity",
                systemImage: "bell.slash",
                description: Text("새 알림이 오면 여기에 표시됩니다.")
            )
        } else {
            List(store.items) { item in
                VStack(alignment: .leading, spacing: .dsXS) {
                    Text(item.title)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextPrimary)
                    Text(item.subtitle)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                .padding(.vertical, .dsXS)
            }
        }
    }
}

#Preview("Items") {
    ActivityView(
        store: Store(initialState: ActivityFeature.State(items: [
            .init(id: 1, title: "Ada followed you", subtitle: "방금 전"),
            .init(id: 2, title: "Alan liked your post", subtitle: "5분 전")
        ])) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient = .previewValue
        }
    )
}

#Preview("Empty") {
    ActivityView(
        store: Store(initialState: ActivityFeature.State()) {
            ActivityFeature()
        } withDependencies: {
            $0.activityClient = ActivityClient(fetchActivities: { [] }, clearAll: {})
        }
    )
}

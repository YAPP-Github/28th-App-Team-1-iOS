//
//  ActivityView.swift
//  ActivityFeature
//
//  Created by EunseoKim on 5/27/26.
//

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
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.items.isEmpty {
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
        store: Store(initialState: ActivityFeature.State()) {
            ActivityFeature()
        }
    )
}

#Preview("Empty") {
    ActivityView(
        store: Store(initialState: ActivityFeature.State(items: [])) {
            ActivityFeature()
        }
    )
}

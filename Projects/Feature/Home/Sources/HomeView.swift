//
//  HomeView.swift
//  HomeFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: .dsXL) {
                Text(store.greeting)
                    .font(.dsLargeTitle)
                    .foregroundStyle(Color.dsTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Tapped \(store.tapCount) times")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)

                PrimaryButton("Tap me") {
                    store.send(.primaryButtonTapped)
                }
                .padding(.horizontal, .dsXL)
            }
            .padding(.dsL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.dsBackground)
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}

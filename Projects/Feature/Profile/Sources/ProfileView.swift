//
//  ProfileView.swift
//  ProfileFeature
//
//  Created by EunseoKim on 5/26/26.
//

import ComposableArchitecture
import DomainProfileInterface
import SwiftUI

public struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        Form {
            if store.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading…").foregroundStyle(.secondary)
                }
            } else if store.profile != nil {
                Section("Display name") {
                    TextField("Display name", text: $store.editedDisplayName)
                        .textInputAutocapitalization(.words)
                }
                Section("Bio") {
                    TextField("Bio", text: $store.editedBio, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let location = store.profile?.location {
                    Section("Location") {
                        Text(location).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.userTappedSaveButton)
                } label: {
                    if store.isSaving {
                        ProgressView()
                    } else {
                        Text("Save").bold()
                    }
                }
                .disabled(store.profile == nil || store.isSaving)
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

#Preview {
    NavigationStack {
        ProfileView(
            store: Store(initialState: ProfileFeature.State(profileId: 1)) {
                ProfileFeature()
            } withDependencies: {
                $0.profileClient = .previewValue
            }
        )
    }
}

import ComposableArchitecture
import SwiftUI

struct UserDetailView: View {
    @Bindable var store: StoreOf<UserDetailFeature>

    var body: some View {
        Form {
            Section("Profile") {
                LabeledContent("Name", value: store.user.name)
                LabeledContent("Email", value: store.user.email)
            }
            Section("Bio") {
                if store.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading…").foregroundStyle(.secondary)
                    }
                } else {
                    Text(store.user.bio ?? "No bio available.")
                }
            }
            Section {
                Button("Edit Profile") {
                    store.send(.userTappedEditButton)
                }
            }
        }
        .navigationTitle(store.user.name)
        .navigationBarTitleDisplayMode(.inline)
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
        UserDetailView(
            store: Store(
                initialState: UserDetailFeature.State(
                    user: User(id: 1, name: "Ada Lovelace", email: "ada@example.com")
                )
            ) {
                UserDetailFeature()
            } withDependencies: {
                $0.userClient = .previewValue
            }
        )
    }
}

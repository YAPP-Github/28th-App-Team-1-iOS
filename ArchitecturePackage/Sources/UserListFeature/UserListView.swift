import ComposableArchitecture
import Models
import SwiftUI
import UserClient

public struct UserListView: View {
    @Bindable var store: StoreOf<UserListFeature>

    public init(store: StoreOf<UserListFeature>) {
        self.store = store
    }

    public var body: some View {
        content
            .navigationTitle("Users")
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

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.users.isEmpty {
            ProgressView()
        } else {
            List(store.users) { user in
                Button {
                    store.send(.userTappedRow(user))
                } label: {
                    UserRow(user: user)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct UserRow: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name).font(.headline)
            Text(user.email).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Loaded") {
    NavigationStack {
        UserListView(
            store: Store(initialState: UserListFeature.State()) {
                UserListFeature()
            } withDependencies: {
                $0.userClient = .previewValue
            }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        UserListView(
            store: Store(initialState: UserListFeature.State(isLoading: true)) {
                UserListFeature()
            } withDependencies: {
                $0.userClient = .previewValue
            }
        )
    }
}

import ComposableArchitecture
import SwiftUI

/// ``ProfileFeature`` 의 SwiftUI 화면.
///
/// 폼 입력은 `$store.editedDisplayName` 식으로 ``ProfileFeature/Action/binding(_:)``
/// 액션을 통해 전파됩니다. View 가 직접 상태를 변경하지 않는다는 원칙은 지켜집니다.
struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
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
